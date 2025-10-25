# Compiling:
# nim c -d:ImSpinner glfw_opengl3_imspinner.nim

import ../utils/[appImGui, infoWindow]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

#---------------------------------------
# Enable ImSipnner widgets respectively
#---------------------------------------
# See: https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.h
#      https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.cpp
{.passC:"-D SPINNER_RAINBOWMIX".}
{.passC:"-D SPINNER_DNADOTS".}
{.passC:"-D SPINNER_ANG8".}
{.passC:"-D SPINNER_CLOCK".}
{.passC:"-D SPINNER_PULSAR".}
{.passC:"-D SPINNER_DOTSTOBAR".}
{.passC:"-D SPINNER_ATOM".}
{.passC:"-D SPINNER_BARCHARTRAINBOW".}
{.passC:"-D SPINNER_SWINGDOTS".}
{.passC:"-D SPINNER_CAMERA".}

#----------------------------
# Enable ImSipnner full demo
#----------------------------
{.passC:"-D IMSPINNER_DEMO".}

const MainWinWidth = 1024
const MainWinHeight = 800

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui Window")
  defer: destroyImGui(win)

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    infoWindow(win)

    #---------------------
    # ImSpinner full demo
    #---------------------
    block:
      igBegin("ImSpinner full demo", nil, 0)
      defer: igEnd()
      demoSpinners()

    #-----------------
    # CImSpinner demo
    #-----------------
    block:
      igBegin("Nim: CImSpinner / ImSpinner demo 2025/02", nil, 0)
      defer: igEnd()
      const red   = ImColor(Value: ImVec4(x: 1.0,      y: 0.0,         z: 0.0, w: 1.0))
      const gold  = ImColor(Value: ImVec4(x: 1.0,      y: 215/255.0,   z: 0.0, w: 1.0))
      const blue1 = ImColor(Value: ImVec4(x: 51/255.0, y: 153/255.0,   z: 1.0, w: 1.0))

      SpinnerDnaDotsEx(      "DnaDots", 16, 2, blue1, 1.2, 8, 0.25, true) ;igSameLine() # Defined by "SPINNER_DNADOTS"
      SpinnerRainbowMix(     "Rmix",    16, 2, gold, 4)                   ;igSameLine() # Defined by "SPINNER_RAINBOWMIX"
      SpinnerAng8(           "Ang",     16, 2)                            ;igSameLine() # ...
      SpinnerPulsar(         "Pulsar",  16, 2)                            ;igSameLine()
      SpinnerClock(          "Clock",   16, 2)                            ;igSameLine()
      SpinnerAtom(           "atom",    16, 2)                            ;igSameLine()
      SpinnerSwingDots(      "wheel",   16, 6)                            ;igSameLine()
      SpinnerDotsToBar(      "tobar",   16, 2, 0.5)                       ;igSameLine()
      SpinnerBarChartRainbow("rainbow", 16, 4, red, 4)                    ;igSameLine()

      proc genColor(i:cint): ImColor {.cdecl.} =
        var col: ImColor
        ImColor_HSV(addr col, i.float32 * 0.25, 0.8, 0.8, 1.0)
        return col
      SpinnerCamera(         "Camera",  16, 8, genColor)  # Defined by "SPINNER_CAMERA"

    #--------
    # render
    #--------
    render(win)

  #### end while

#------
# main
#------
main()
