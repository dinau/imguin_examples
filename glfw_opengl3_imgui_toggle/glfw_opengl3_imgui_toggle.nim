# Compiling:
# nim c -d:ImGuiToggle glfw_opengl3_imgui_toggle

import ../utils/[appImGui, infoWindow]
import ./imgui_toggle_demo

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

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    infoWindow(win)

    # Show imgui_toggle / cimgui_toggle demo
    block:
      igBegin("ImGui toggle demo", nil, 0)
      defer: igEnd()
      imgui_toggle_example()

    #--------
    # render
    #--------
    render(win)

    #if not showDemoWindow:
    #  win.handle.setWindowShouldClose(true) # Exit program

  #### end while

#------
# main
#------
main()
