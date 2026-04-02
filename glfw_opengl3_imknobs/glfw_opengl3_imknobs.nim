# Compiling:
# nim c -d:ImKnobs --warning:HoleEnumConv:off glfw_opengl3_imknobs

import ../utils/appImGui
import ./demoKnobs

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 800

#----------
# gui_main
#----------
proc gui_main(win: var AppWindow) =
  var
    showKnobsWindow = true

  let pio = igGetIO()

  var val1 : cfloat = 0.6
  var val2 : cint = 1
  var val3 : cfloat = 1

  #-----------
  # main loop
  #-----------
  while not win.shouldClose:
    win.pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    win.infoWindow()

    #-----------------------
    # Show ImGui-Knobs demo
    #-----------------------
    demoKnobs(win.ini.clearColor.elm.x, win.ini.clearColor.elm.y, win.ini.clearColor.elm.z, val1, val2, val3)

    render(win)

    if not showKnobsWindow:
      win.shouldClose = true # End program

  #### end while

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title = "ImGui-knobs demo")
  defer: destroyImGui(win)

  discard setupFonts()

  gui_main(win)

#------
# main
#------
main()
