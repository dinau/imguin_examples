# Compiling:
# nim c glfw_opengl3_image_load

import std/[os]
import ../utils/appImGui

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 900

#----------
# gui_main
#----------
proc gui_main(win: var AppWindow) =
  #-------------
  # Load image
  #-------------
  var
    textureId: GLuint
    textureWidth = 0
    textureHeight = 0
  var ImageName = os.joinPath(os.getAppDir(), "fuji-400.jpg")
  loadTextureFromFile(ImageName, textureId, textureWidth, textureHeight)
  defer: glDeleteTextures(1, addr textureId)

  #-----------
  # main loop
  #-----------
  while not win.shouldClose:
    win.pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    win.infoWindow()

    # Show image load window
    block:
      igBegin("Image load test", nil, 0)
      defer: igEnd()
      # Load image
      let
        size = vec2(textureWidth, textureHeight)
        uv0 = vec2(0, 0)
        uv1 = vec2(1, 1)
      let imageBoxPosTop = igGetCursorScreenPos() # Get absolute pos.
      igImage(ImTextureRef(internal_TexData: nil, internal_TexID: textureId), size, uv0, uv1)
      let imageBoxPosEnd = igGetCursorScreenPos() # Get absolute pos.
                                                  #
      if igIsItemHovered(ImGui_HoveredFlags_DelayNone.ImGuiHoveredFlags):
        zoomGlass(textureId, textureWidth, imageBoxPosTop, imageBoxPosEnd)

    render(win)

    #if not showDemoWindow:
    #  win.shouldClose = true # End program

  #### end while

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight)
  defer: destroyImGui(win)

  discard setupFonts()

  gui_main(win)

#------
# main
#------
main()
