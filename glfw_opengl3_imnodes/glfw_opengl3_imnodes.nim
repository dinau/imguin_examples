# Compiling:
# nim c -d:ImNodesEnable glfw_opengl3_imnodes

import ../utils/appImGui

import imnodeDemo

const MainWinWidth = 1024
const MainWinHeight = 800

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, imnodes = true, title="ImNodes demo")
  defer: destroyImGui(win)

  # ImNode demo init
  NodeEditorInitialize()
  defer: NodeEditorShutdown()

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    igShowDemoWindow(nil)

    # ImNodes demo
    NodeEditorShow()
    #
    render(win)

  #### end while

#------
# main
#------
main()
