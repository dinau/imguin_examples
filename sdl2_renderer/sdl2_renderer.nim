# Compiling:
# nim c -d:SDL sdl2_renderer2.nim

import std/[os]
import ../utils/appImGuiSdlrenderer2

when defined(windows):
  include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 900

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui: SDL2-renderer")
  defer: destroyImGui(win)

  var
    showDemoWindow = true
    showFirstWindow = true
    fval = 0.5f
    counter = 0
    xQuit: bool
    sBuf = newString(200)

  #-------------
  # Load image
  #-------------
  var
    textureId: sdl.Texture
    textureWidth = 0
    textureHeight = 0
  var ImageName = os.joinPath(os.getAppDir(),"fuji-400.jpg")
  loadTextureFromFile(ImageName, win.renderer, textureId, textureWidth,textureHeight)

  let pio = igGetIO()

  #-----------
  # Main loop
  #-----------
  while not xQuit:
    var event: Event
    while 0 != sdl.pollevent(addr event):
      ImGui_ImplSDL2_ProcessEvent(cast[ptr SdlEvent](addr event))
      if event.kind == QUIT:
        xQuit = true
      if event.kind == WINDOWEVENT and event.window.event ==
          WINDOWEVENT_CLOSE and
        event.window.windowID == sdl.getWindowID(win.handle):
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
      igBegin("Nim: Dear ImGui test with Futhark", showFirstWindow.addr, 0)
      defer: igEnd()

      igText((ICON_FA_COMMENT & " " & getFrontendVersionString()).cstring)
      igText((ICON_FA_COMMENT_SMS & " " & getBackendVersionString()).cstring)
      igText("%s %s", ICON_FA_COMMENT_DOTS & " Dear ImGui", igGetVersion())
      igText("%s%s", ICON_FA_COMMENT_MEDICAL & " Nim-", NimVersion)

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
      #
      igSeparatorText(ICON_FA_WRENCH & " Icon font test ")
      igText(ICON_FA_TRASH_CAN & " Trash")
      igText(ICON_FA_MAGNIFYING_GLASS_PLUS &
        " " & ICON_FA_POWER_OFF &
        " " & ICON_FA_MICROPHONE &
        " " & ICON_FA_MICROCHIP &
        " " & ICON_FA_VOLUME_HIGH &
        " " & ICON_FA_SCISSORS &
        " " & ICON_FA_SCREWDRIVER_WRENCH &
        " " & ICON_FA_BLOG)

    # Show image load window
    block:
      igBegin("Image load test", nil, 0)
      defer: igEnd()
      # Load image
      let
        size = vec2(textureWidth, textureHeight)
        uv0 = vec2(0, 0)
        uv1 = vec2(1, 1)
      var
        imageBoxPosTop:ImVec2
      igGetCursorScreenPos(addr imageBoxPosTop) # Get absolute pos.
      igImage(ImTextureRef(internal_TexData: nil, internal_TexID: cast[ImTextureID](textureId)), size, uv0, uv1)
      # Magnifiying glass TODO: Not works well on Linux OS ?.
      if igIsItemHovered(ImGui_HoveredFlags_DelayNone.ImGuiHoveredFlags):
        zoomGlass(cast[ImTextureID](textureId), textureWidth, textureHeight, imageBoxPosTop)

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
