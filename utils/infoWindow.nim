import imguin/[cimgui, glfw_opengl, simple]
import ../utils/[utils, appImGui, setupFonts, togglebutton]

proc infoWindow*(win: var Window) =
  var
    sw{.global.}:bool
    strSw{.global.}:string
    showDemoWindow{.global.} = true
  once:
    let theme = win.getTheme()
    sw = if theme == Theme.Light: false else: true
    strSw = $theme

  if showDemoWindow:
    igShowDemoWindow(addr showDemoWindow)

  block:
    igBegin("Info window", nil, 0)
    defer: igEnd()
    if igToggleButton(strSw, sw):
      if sw:
        strSw = win.setTheme(Classic)
      else:
        strSw = win.setTheme(Light)
    #
    igText((ICON_FA_COMMENT & " " & getFrontendVersionString()).cstring)
    igText((ICON_FA_COMMENT_SMS & " " & getBackendVersionString()).cstring)
    igText("%s %s", ICON_FA_COMMENT_DOTS & " Dear ImGui", igGetVersion())
    igText("%s%s", ICON_FA_COMMENT_MEDICAL & " Nim-", NimVersion)
    igCheckbox("ImGui Demo", addr showDemoWindow)
    igColorEdit3("Background color", win.ini.clearColor.array3, 0.ImGuiColorEditFlags)
    igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, igGetIO().Framerate.cfloat)
