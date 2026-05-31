# Compiling for desktop application:
#   $ make app
#   or
#   $ nim c -d:strip glfw_opengl3_imgui_zoomable_image.nim
#
# Compiling for Emscripten (WebAssembly):
#   $ make
#   or
#   $ make run
#
# See ./Makefile, ./config.nims

import std/[os]
import ../utils/[appImGuiWasm, utils, setupFonts, vecs]
import ../utils/opengl/[loadImage]
import ../licenses_window/licenseNotices

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

var
  win: AppWindow
  zoomState: ImGuiImageState #   preserved across frames to maintain zoom and pan state.
  textureWidth = 0
  textureHeight = 0
  textureRef: ImTextureRef

#----------
# gui_main
#----------
proc gui_main() =
  var showLicenseNotices  {.global.} = false

  #-------------
  # Load image
  #-------------
  var
    textureId: GLuint
  var ImageName = os.joinPath(os.getAppDir(), "img/dinosaurs_paradise.jpg")
  loadTextureFromFile(ImageName, textureId, textureWidth, textureHeight)
  defer: glDeleteTextures(1, addr textureId)
  # Set textureID
  textureRef.internal_TexID = textureId


  #---------------------------
  # Init imgui_zoomable_image
  #---------------------------
  ImGuiImage_State_Init( addr zoomState);

  #-----------
  # main loop
  #-----------
  emscriptenMainloopBegin(win):
    win.pollEvents()

    newFrame()

    #--------------------
    # Show Licenses menu
    #--------------------
    let mh = igGetFrameHeight()
    if igBeginMainMenuBar():
      defer: igEndMainMenuBar()
      if igBeginMenu("Licenses", true):
        defer: igEndMenu()
        if igMenuItem("Show", nil):
          if not showLicenseNotices:
            showLicenseNotices = true

    #-----------------------
    # Show Licenses window
    #-----------------------
    if showLicenseNotices:
      win.setTheme(Light)
      igSetNextWindowSize(vec2(600, 800), ImGui_Cond_FirstUseEver.cint)
      licenseNotices(addr showLicenseNotices)
      win.setTheme(Classic)

    # infowindow
    igSetNextWindowCollapsed(true, ImGuiCond_FirstUse_Ever.cint) # For ImGui demo window
    infoWindow(win, vec2(650, 430))

    let imageWindowPos    = vec2(10, 10 + mh)
    let imageWindowSize   = vec2(540, 340)
    let controlsWindowPos = vec2(650, 50)

    #---------------------------
    # ImGui Zoomable Image demo
    #---------------------------
    igSetNextWindowPos(imageWindowPos, ImGuiCond_FirstUse_Ever.cint, vec2(0, 0))
    igSetNextWindowSize(imageWindowSize, ImGuiCond_FirstUse_Ever.cint)
    zoomState.textureSize = vec2(textureWidth, textureHeight)
    igBegin("Imgui Zoomable Image demo in Nim " & ICON_FA_CAT, nil, 0)
    var displaySize = igGetContentRegionAvail();
    ImGuiImage_Zoomable(textureRef, addr displaySize, addr zoomState);
    igEnd()

    #--------------------------
    # Create a controls window
    #--------------------------
    igSetNextWindowPos(controlsWindowPos, ImGuiCond_FirstUse_Ever.cint, vec2(0, 0))
    igBegin("Controls Window", nil, 0)
    igCheckbox("Enable Zoom/Pan", addr zoomState.zoomPanEnabled)
    igCheckbox("Maintain Aspect Ratio", addr zoomState.maintainAspectRatio)
    if igButton("Reset Zoom/Pan", vec2(0, 0)):
      zoomState.zoomLevel = 1.0f
      zoomState.panOffset = vec2(0.0f, 0.0f)
    igSeparator()
    igText("Texture Size: %zu x %zu", textureWidth, textureHeight);
    igText("Display Size: %.0f x %.0f", displaySize.x, displaySize.y);
    igText("Zoom Level: %.2f%%", zoomState.zoomLevel * 100.0f);
    igText("Pan Offset: (%.2f, %.2f)", zoomState.panOffset.x * textureWidth.cfloat,
                                            zoomState.panOffset.y * textureHeight.cfloat);
    igText("Mouse Pos: (%.2f, %.2f)", zoomState.mousePosition.x,
                                           zoomState.mousePosition.y);
    igEnd();
    #--------
    # render
    #--------
    render(win)

  #### end while

#------
# main
#------
proc main() =
  win = createImGui(MainWinWidth, MainWinHeight, title = "ImGui Window in Nim")
  defer: destroyImGui(win)

  discard setupFonts()
  discard win.setTheme(Classic)

  gui_main()

#------
# main
#------
main()
