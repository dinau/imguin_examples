# Compiling:
# nim c -d:ImGuiToggle glfw_opengl3_imgui_toggle

import ../utils/appImGui
import ./imgui_toggle_demo

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

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
    #  win.shouldClose = true # Exit program

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
