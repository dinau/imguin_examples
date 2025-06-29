# Compiling:
# nim c -d:ImSpinner glfw_opengl3_imspinner.nim

import std/[paths,math]
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
{.passC:"-DSPINNER_RAINBOWMIX".}
{.passC:"-DSPINNER_DNADOTS".}
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

    #----------------
    # CImSpinner demo
    #----------------
    block:
      igBegin("Nim: CImSpinner / ImSpinner demo 2025/02", nil, 0)
      defer: igEnd()
      const red  = ImColor(Value: ImVec4(x: 1.0,   y : 0.0,   z : 0.0, w : 1.0))
      const gold = ImColor(Value: ImVec4(x: 255.0, y : 215.0, z : 0.0, w : 1.0))
      SpinnerDnaDotsEx("DnaDots", 16, 2, red, 1.2, 8, 0.25, true)
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
    #--------
    # render
    #--------
    render(win)

    #if  not showDemoWindow:
    #  win.handle.setWindowShouldClose(true) # Exit program

  #### end while

#------
# main
#------
main()
