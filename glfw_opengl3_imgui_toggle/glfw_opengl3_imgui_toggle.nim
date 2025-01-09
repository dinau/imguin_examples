# Compiling:
# nim c -d:ImGuiToggle glfw_opengl3_imgui_toggle

import ../utils/[appImGui]
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

  type TSw = object
    state: bool
    label: string

  var
    showDemoWindow = true
    showFirstWindow = true
    sw:TSw

  sw.state = if win.getTheme() == classic: true else: false
  sw.label = "Theme " & win.getThemeLabel()

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    # Show imgui_toggle / cimgui_toggle demo
    block:
      igBegin("ImGui toggle demo", nil, 0)
      defer: igEnd()
      imgui_toggle_example()

    # Show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", addr showFirstWindow, 0)
      defer: igEnd()
      if Toggle(sw.label.cstring, addr sw.state, vec2(45,20)):
        if sw.state:
          win.setTheme(classic)
        else:
          win.setTheme(microsoft)
        sw.label = "Theme " & win.getThemeLabel()
      #
      igText((ICON_FA_COMMENT & " " & getFrontendVersionString()).cstring)
      igText((ICON_FA_COMMENT_SMS & " " & getBackendVersionString()).cstring)
      igText("%s %s", ICON_FA_COMMENT_DOTS & " Dear ImGui", igGetVersion())
      igText("%s%s", ICON_FA_COMMENT_MEDICAL & " Nim-", NimVersion)

      igCheckbox("Demo window", addr showDemoWindow)
      igColorEdit3("Background color", win.ini.clearColor.array3, 0.ImGuiColorEditFlags)
      igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, igGetIO().Framerate.cfloat)

    #--------
    # render
    #--------
    render(win)
    if not showFirstWindow and not showDemoWindow:
      win.handle.setWindowShouldClose(true) # Exit program

  #### end while

#------
# main
#------
main()
