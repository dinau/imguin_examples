# Compiling:
# nim c -d:ImSpinner glfw_opengl3_imspinner.nim

import std/[paths,math]
import ../utils/[appImGui, togglebutton]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs


#---------------------------------------
# Enable ImSipnner widgets respectively
#---------------------------------------
# See: https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.h
{.passC:"-DSPINNER_RAINBOWMIX".}
{.passC:"-DSPINNER_ROTATINGHEART".}
{.passC:"-DSPINNER_ANG8".}
{.passC:"-DSPINNER_CLOCK".}
{.passC:"-DSPINNER_PULSAR".}
{.passC:"-DSPINNER_DOTSTOBAR".}
{.passC:"-DSPINNER_ATOM".}
{.passC:"-DSPINNER_BARCHARTRAINBOW".}
{.passC:"-DSPINNER_SWINGDOTS".}

#----------------------------
# Enable ImSipnner full demo
#----------------------------
{.passC:"-DIMSPINNER_DEMO".}


const MainWinWidth = 1024
const MainWinHeight = 800

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui Window")
  defer: destroyImGui(win)

  var
    showDemoWindow = true
    showAnotherWindow = false
    showFirstWindow = true
    fval = 0.5f
    counter = 0
    sBuf = newString(200)
    sFnameSelected{.global.}:Path
    sw:bool
    strSw:string

  if win.getTheme() == classic:
    sw = false
    strSw = "OFF"
  else:
    sw = true
    strSw = "ON"

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    #---------------------
    # ImSpinner full demo
    #---------------------
    block:
      igBegin("ImSpinner full demo", nil, 0)
      defer: igEnd()
      demoSpinners()

    #----------------
    # CImSpinner demo
    #----------------
    block:
      igBegin("Nim: CImSpinner / ImSpinner demo 2025", nil, 0)
      defer: igEnd()
      const red  = ImColor(Value: ImVec4(x: 1.0,   y : 0.0,   z : 0.0, w : 1.0))
      const gold = ImColor(Value: ImVec4(x: 255.0, y : 215.0, z : 0.0, w : 1.0))
      SpinnerRotatingHeart("RHeart", 16, 2, red, 4)
      igSameLine()
      SpinnerRainbowMix("Rmix", 16, 2, gold, 4)
      igSameLine()
      SpinnerAng8("Ang", 16, 2)
      igSameLine()
      SpinnerPulsar("Pulsar", 16, 2)
      igSameLine()
      SpinnerClock("Clock", 16, 2)
      igSameLine()
      SpinnerAtom("atom", 16, 2)
      igSameLine()
      SpinnerSwingDots("wheel", 16, 6)
      igSameLine()
      SpinnerDotsToBar("tobar", 16, 2, 0.5)
      igSameLine()
      SpinnerBarChartRainbow("rainbow", 16, 4, red, 4)

    # show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", addr showFirstWindow, 0)
      defer: igEnd()
      if igToggleButton(strSw, sw):
        if sw:
          strSw = "ON"
          win.setTheme(microsoft)
        else:
          strSw ="OFF"
          win.setTheme(classic)
      #
      igText((ICON_FA_COMMENT & " " & getFrontendVersionString()).cstring)
      igText((ICON_FA_COMMENT_SMS & " " & getBackendVersionString()).cstring)
      igText("%s %s", ICON_FA_COMMENT_DOTS & " Dear ImGui", igGetVersion())
      igText("%s%s", ICON_FA_COMMENT_MEDICAL & " Nim-", NimVersion)

      igInputTextWithHint("InputText" ,"Input text here" ,sBuf)
      igText(("Input result:" & sBuf).cstring)
      igCheckbox("Demo window", addr showDemoWindow)
      igCheckbox("Another window", addr showAnotherWindow)
      igSliderFloat("Float", addr fval, 0.0f, 1.0f, "%.3f", 0)
      igColorEdit3("Background color", win.ini.clearColor.array3, 0.ImGuiColorEditFlags)

      # Show file open dialog
      when defined(windows):
        if igButton("Open file", vec2(0, 0)):
           sFnameSelected = openFileDialog("File open dialog", (getCurrentDir() / "\0".Path).string, ["*.nim", "*.nims"], "Text file").Path
        igSameLine(0.0f, -1.0f)
        # Show hint
        if igIsItemHovered(Imgui_HoveredFlagsDelayShort.cint) and igBeginTooltip():
          igText("[Open file]")
          const ary = [0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f]
          igPlotLines("Curve", ary, overlayText = "Overlay string")
          igText("Sin(time) = %.2f", sin(igGetTime()));
          igEndTooltip();
        let (_,fname,ext) = sFnameSelected.splitFile()
        igText("Selected file = %s", (fname.string & ext).cstring)
      # Counter up
      if igButton("Button", vec2(0.0f, 0.0f)):
        inc counter
      igSameLine()
      igText("counter = %d", counter)
      igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, igGetIO().Framerate.cfloat)
      igSeparatorText(ICON_FA_WRENCH & " Icon font test ")
      igText(ICON_FA_TRASH_CAN & " Trash")
      igText(ICON_FA_MAGNIFYING_GLASS_PLUS &
        " " & ICON_FA_POWER_OFF &
        " " & ICON_FA_MICROPHONE &
        " " & ICON_FA_MICROCHIP &
        " " & ICON_FA_VOLUME_HIGH &
        " " & ICON_FA_SCISSORS &
        " " & ICON_FA_SCREWDRIVER_WRENCH &
        " " & ICON_FA_BLOG)

    # show further samll window
    if showAnotherWindow:
      igBegin("imgui Another Window", addr showAnotherWindow, 0)
      igText("Hello from imgui")
      if igButton("Close me", vec2(0.0f, 0.0f)):
        showAnotherWindow = false
      igEnd()

    #--------
    # render
    #--------
    render(win)
    if not showFirstWindow and not showDemoWindow and not showAnotherWindow:
      win.handle.setWindowShouldClose(true) # Exit program

  #### end while

#------
# main
#------
main()
