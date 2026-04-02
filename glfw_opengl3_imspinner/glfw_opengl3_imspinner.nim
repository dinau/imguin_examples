# Compiling:
# nim c -d:ImSpinner glfw_opengl3_imspinner.nim

import ../utils/appImGui
import ./demoCImSpinners

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

#---------------------------------------
# Enable ImSipnner widgets respectively
#---------------------------------------
# See: https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.h
#      https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.cpp
{.passC: "-D SPINNER_RAINBOWMIX".}
{.passC: "-D SPINNER_DNADOTS".}
{.passC: "-D SPINNER_ANG8".}
{.passC: "-D SPINNER_CLOCK".}
{.passC: "-D SPINNER_PULSAR".}
{.passC: "-D SPINNER_DOTSTOBAR".}
{.passC: "-D SPINNER_ATOM".}
{.passC: "-D SPINNER_BARCHARTRAINBOW".}
{.passC: "-D SPINNER_SWINGDOTS".}
{.passC: "-D SPINNER_CAMERA".}

#----------------------------
# Enable ImSipnner full demo
#----------------------------
{.passC: "-D IMSPINNER_DEMO".}

const MainWinWidth = 1024
const MainWinHeight = 800

#----------
# gui_main
#----------
proc gui_main(win: var AppWindow) =
  #-----------
  # main loop
  #-----------
  while not win.shouldClose:
    win.pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    win.infoWindow()

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
    demoCImSpinners()

    #--------
    # render
    #--------
    render(win)

  #### end while

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title = "ImGui Window")
  defer: destroyImGui(win)

  discard setupFonts()

  gui_main(win)

#------
# main
#------
main()
