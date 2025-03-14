# Compiling:
# nim c glfw_opengl3_base

import std/[paths,math]
import ../utils/[appImGui, togglebutton, infoWindow]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui Window base")
  defer: destroyImGui(win)

  var
    showAnotherWindow = false
    showFirstWindow = true
    fval = 0.5f
    counter = 0
    sBuf = newString(200)
    sFnameSelected{.global.}:Path

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    infoWindow(win)

    # show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", addr showFirstWindow, 0)
      defer: igEnd()
      #
      igInputTextWithHint("InputText" ,"Input text here" ,sBuf)
      igText(("Input result:" & sBuf).cstring)
      igCheckbox("Another window", addr showAnotherWindow)

      # Show file open dialog
      when defined(windows):
        if igButton("Open file", vec2(0, 0)):
           sFnameSelected = openFileDialog("File open dialog", (getCurrentDir() / "\0".Path).string, ["*.nim", "*.nims"], "Text file").Path
        igSameLine()
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
    if not showFirstWindow and not showAnotherWindow:
      win.handle.setWindowShouldClose(true) # Exit program

  #### end while

#------
# main
#------
main()
