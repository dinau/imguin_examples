# Compiling:
# nim c -d:SDL sdl3_sdlgpu3

import std/[os]
import ../utils/appImGuiSdlgpu3


when defined(windows):
  include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 900

const fImageLoad = false # TODO


#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui window: SDL3GPU backend")
  defer: destroyImGui(win)

  var
    showDemoWindow = true
    showFirstWindow = true
    fval = 0.5f
    counter = 0
    xQuit: bool
    sBuf = newString(200)

  #discard setupFonts() # TODO Add multibytes font

  igStyleColorsDark(nil)

  #-------------
  # Load image
  #-------------
  var
    textureId: ptr SDL_GPUTexture
    textureWidth:cint = 0
    textureHeight:cint = 0
  var ImageName = os.joinPath(os.getAppDir(),"fuji-400.jpg")
  #discard loadTextureFromFileSDLGPU3(ImageName, win.gpu_device, textureId, textureWidth,textureHeight)

  let pio = igGetIO()

  #-----------
  # Main loop
  #-----------
  var event: SDL_Event
  while not xQuit:
    var event: SDL_Event
    while SDL_pollevent(addr event):
      discard ImGui_ImplSDL3_processEvent(addr event)
      if event.type_field == SDL_EVENT_QUIT.uint32:
        xQuit = true
      if event.type_field == SDL_EVENT_WINDOW_CLOSE_REQUESTED.uint32 and event.window.windowID == SDL_GetWindowID(win.handle):
        xQuit = true

    if isIconifySleep(win):
      continue
    newFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    #-----------------
    # showFirstWindow
    #-----------------
    if showFirstWindow:
      igBegin("Nim: Dear ImGui in Nim lang.", showFirstWindow.addr, 0)
      defer: igEnd()

      igText((getFrontendVersionString()).cstring)
      igText((getBackendVersionString()).cstring)
      igText("%s %s", " Dear ImGui", igGetVersion())
      igText("%s%s", " Nim-", NimVersion)

      igInputTextWithHint("InputText" ,"Input text here" ,sBuf)
      igText(("Input result:" & sBuf).cstring)
      igCheckbox("Demo window", addr showDemoWindow)
      igSliderFloat("Float", addr fval, 0.0f, 1.5f, "%.3f", 0)
      igColorEdit3("Background color", win.ini.clearColor.array3, ImGuiColorEditFlags_None.ImGuiColorEditFlags)

      if igButton("Button", vec2(0.0f, 0.0f)):
        inc counter
      igSameLine(0.0f, -1.0f)
      igText("counter = %d", counter)
      igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / pio.Framerate.float, pio.Framerate)

    # Show image load window
    when fImageLoad:
      igBegin("Image load test", nil, 0)
      defer: igEnd()
      # Load image
      let
        size = vec2(textureWidth, textureHeight)
        uv0 = vec2(0, 0)
        uv1 = vec2(1, 1)
      var
        imageBoxPosTop:ImVec2
        imageBoxPosEnd:ImVec2
      igGetCursorScreenPos(addr imageBoxPosTop) # Get absolute pos.
      igImage(ImTextureRef(internal_TexData: nil, internal_TexID: cast[ImTextureID](textureId)), size, uv0, uv1)
      igGetCursorScreenPos(addr imageBoxPosEnd) # Get absolute pos.
      # Magnifiying glass
      if igIsItemHovered(ImGui_HoveredFlags_DelayNone.ImGuiHoveredFlags):
        zoomGlass(cast[var int32](textureId), textureWidth, imageBoxPosTop, imageBoxPosEnd)

    #--------
    # render
    #--------
    render(win)
    if not showFirstWindow and not showDemoWindow :
      xQuit = true

  ### end while

#------
# main
#------
main()
