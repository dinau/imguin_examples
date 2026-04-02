# Compiling for desktop application:
#   nim c -d:strip  glfw_opengl3_wasm_base.nim
# Compiling for Emscripten (WebAssembly):
#   $ make
# See ./Makefile, ./config.nims

import std/[os, random]
import ../utils/[appImGuiWasm, utils, setupFonts, vecs]
import ../utils/opengl/[loadImage, zoomglass]
import ../glfw_opengl3_imspinner/demoCImSpinners
import ../glfw_opengl3_implot3d/demoImPlot3d
import ../glfw_opengl3_imknobs/demoKnobs

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource

var
  win: AppWindow

proc gui_main() =
  #-------------------
  # Setting ImPlot/3D
  #-------------------
  let imPlotContext = ImPlot_CreateContext()
  defer: imPlotContext.ImPlotDestroyContext()
  let imPlot3dContext = ImPlot3d_CreateContext()
  defer: imPlot3dContext.ImPlot3dDestroyContext()
  discard initRand()

  # Set docking feature enable
  #var pio = igGetIO_Nil()
  #pio.ConfigFlags = pio.ConfigFlags or ImGuiConfigFlags_DockingEnable.cint   # Enable Docking

  #----------------
  # For load image
  #----------------
  var
    textureId{.global.}: cuint
    textureWidth {.global.} = 0
    textureHeight{.global.} = 0
    size{.global.}: Vec2
  var ImageName = os.joinPath(os.getAppDir(), "img/animal_paradise-480.gif")
  loadTextureFromFile(ImageName, textureId, textureWidth, textureHeight)
  defer: glDeleteTextures(1, addr textureId)

  var val4 {.global.}: cfloat = 0.6
  var val5 {.global.}: cint = 1
  var val6 {.global.}: cfloat = 1

  #-----------
  # Main loop
  #-----------
  emscriptenMainloopBegin(win.glfwWin):
    win.pollEvents()

    newFrame()

    #-------------------
    # ImImPlot/3D demo
    #-------------------
    ImplotShowDemoWindow (nil)
    Implot3dShowDemoWindow(nil)

    #-----------------
    # CImSpinner demo
    #-----------------
    igSetNextWindowPos(vec2(10, 10), ImGui_Cond_FirstUseEver.cint, vec2(0, 0)) # For WASM
    demoCImSpinners()

    #------------
    # infoWindow
    #------------
    win.infoWindow(vec2(10, 100))

    #---------------
    # ImKnobs demo
    #---------------
    igSetNextWindowPos(vec2(10, 300), ImGui_Cond_FirstUseEver.cint, vec2(0, 0))
    demoKnobs(win.ini.clearColor.elm.x, win.ini.clearColor.elm.y  ,win.ini.clearColor.elm.z  , val4, val5, val6)

    #---------------------
    # ImSpinner full demo
    #---------------------
    block:
      igSetNextWindowPos(vec2(10, 450), ImGui_Cond_FirstUseEver.cint, vec2(0, 0))
      igSetNextWindowSize(vec2(900, 300), ImGui_Cond_FirstUseEver.cint)
      igBegin("ImSpinner full demo", nil, 0)
      defer: igEnd()
      demoSpinners()

    #----------------------
    # ImPlot3D demo window
    #----------------------
    igSetNextWindowPos(vec2(880, 260), ImGui_Cond_FirstUseEver.cint, vec2(0, 0))
    igSetNextWindowSize(vec2(460, 750), ImGui_Cond_FirstUseEver.cint)
    demoImPlot3D()

    #------------------------
    # Show image load window
    #------------------------
    block:
      igSetNextWindowPos(vec2(600, 300), ImGui_Cond_FirstUseEver.cint, vec2(0, 0))
      igBegin("Image load test " & ICON_FA_IMAGE, nil, 0)
      defer: igEnd()
      # Load image
      size = vec2(textureWidth, textureHeight)
      let imageBoxPosTop = igGetCursorScreenPos() # Get absolute pos.
      igSetNextWindowSize(vec2(423, 452), ImGui_Cond_FirstUseEver.cint)
      igImage(ImTextureRef(internal_TexData: nil, internal_TexID: textureId), size, vec2(0, 0), vec2(1, 1))
      let imageBoxPosEnd = igGetCursorScreenPos() # Get absolute pos.
                                                  #
      if igIsItemHovered(ImGui_HoveredFlags_DelayNone.ImGuiHoveredFlags):
        zoomGlass(textureId, textureWidth, imageBoxPosTop, imageBoxPosEnd)

    #--------
    # render
    #--------
    render(win)

#------
# main
#------
proc main() =
  win = createImGui(w = 1280, h = 900)
  defer: win.destroyImGui()

  discard setupFonts()
  discard win.setTheme(Classic)

  gui_main()

#------
# main
#------
main()
