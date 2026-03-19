# Compiling:
# nim c glfw_opengl3.nim

import std/[os, strutils, math]
import glfw
import imguin/[glad/gl]
import imguin/[cimgui, glfw_opengl, simple]
import stb_image/read as stbi
import ../utils/[utils, setupFonts, vecs, togglebutton]

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

#--------------
# Configration
#--------------

#  .--------------------------------------------..---------.-----------------------.------------
#  |         Combination of flags               ||         |     Viewport          |
#  |--------------------------------------------||---------|-----------------------|------------
#  | fViewport | fDocking | TransparentViewport || Docking | Transparent | Outside | Description
#  |:---------:|:--------:|:-------------------:||:-------:|:-----------:|:-------:| -----------
#  |  false    | false    |     false           ||    -    |     -       |   -     |
#  |  false    | true     |     false           ||    v    |     -       |   -     | (Default): Only docking
#  |  true     | -        |     false           ||    v    |     -       |   v     | Docking and outside of viewport
#  |    -      | -        |     true            ||    v    |     v       |   -     | Transparent Viewport and docking
#  `-----------'----------'---------------------'`---------'-------------'---------'-------------
var
  fDocking = true
  fViewport = false
  TransparentViewport = false
  #
block:
  if TransparentViewport:
    fViewport = true
  if fViewport:
    fDocking = true

#---------------------
# Forward definitions
#---------------------
proc loadTileBarIcon*(win: Window, iconName: string)

#----------
# gui_main
#----------
proc gui_main(win: glfw.Window) =
  var
    showDemoWindow = true
    showAnotherWindow = false
    showFirstWindow = true
    fval = 0.5f
    counter = 0
    sBuf = newString(200)
    sFnameSelected{.global.}: string
    clearColor: ccolor
    showWindowDelay = 1 # TODO
    sw: bool
    strSw = "Dark"

  if TransparentViewport:
    clearColor = ccolor(elm: (x: 0f, y: 0f, z: 0f, w: 0.0f)) # Transparent
  else:
    clearColor = ccolor(elm: (x: 0.25f, y: 0.65f, z: 0.85f, w: 1.0f))

  #setTheme(Dark)

  # Add multibytes font
  discard setupFonts()

  var pio = igGetIO()

  # main loop
  while not win.shouldClose:
    glfw.pollEvents()

    if win.iconified:
      ImGui_ImplGlfw_Sleep(10)
      continue

    # start imgui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    igNewFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    # show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", addr showFirstWindow, 0)
      defer: igEnd()
      if igToggleButton(strSw, sw):
        if sw:
          strSw = "Light"
          setTheme(Light)
        else:
          strSw = "Dark"
          setTheme(Dark)
      var s = "GLFW v" & $glfw.versionString()
      s = ICON_FA_COMMENT & " " & s
      igText(s.cstring)
      s = "OpenGL v" & ($cast[cstring](glGetString(GL_VERSION))).split[0]
      s = ICON_FA_COMMENT_SMS & " " & s
      igText(s.cstring)
      igText(ICON_FA_COMMENT_DOTS & " Dear ImGui"); igSameLine(0, -1.0)
      igText(igGetVersion())
      igText(ICON_FA_COMMENT_MEDICAL & " Nim-"); igSameLine(0, 0)
      igText(NimVersion);

      igInputTextWithHint("InputText", "Input text here", sBuf)
      s = "Input result:" & sBuf
      igText(s.cstring)
      igCheckbox("Demo window", addr showDemoWindow); igSameLine()
      igCheckbox("Another window", addr showAnotherWindow)
      igSliderFloat("Float", addr fval, 0.0f, 1.0f, "%.3f", 0)
      igColorEdit3("Background color", clearColor.array3, 0.ImGuiColorEditFlags)

      # Show file open dialog
      when defined(windows):
        if igButton("Open file", vec2(0, 0)):
          sFnameSelected = openFileDialog("File open dialog", getCurrentDir() / "\0", ["*.nim", "*.nims"], "Text file")
        igSameLine(0.0f, -1.0f)
        # Show hint
        if igIsItemHovered(Imgui_HoveredFlagsDelayShort.cint) and igBeginTooltip():
          igText("[Open file]")
          const ary = [0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f]
          igPlotLines("Curve", ary, overlayText = "Overlay string")
          igText("Sin(time) = %.2f", sin(igGetTime()));
          igEndTooltip();
        let (_, fname, ext) = sFnameSelected.splitFile()
        igText("Selected file = %s", (fname & ext).cstring)
      # Counter up
      if igButton("Button", vec2(0.0f, 0.0f)):
        inc counter
      igSameLine(0.0f, -1.0f)
      igText("counter = %d", counter)
      igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, igGetIO().Framerate.cfloat)
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

    # show further samll window
    if showAnotherWindow:
      igBegin("imgui Another Window", addr showAnotherWindow, 0)
      igText("Hello from imgui")
      if igButton("Close me", vec2(0.0f, 0.0f)):
        showAnotherWindow = false
      igEnd()

    # render
    igRender()
    glClearColor(clearColor.elm.x, clearColor.elm.y, clearColor.elm.z, clearColor.elm.w)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())

    if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
      var backup_current_window = glfw.currentContext()
      igUpdatePlatformWindows()
      igRenderPlatformWindowsDefault(nil, nil)
      backup_current_window.makeContextCurrent()

    win.swapBuffers()
    if not showFirstWindow and not showDemoWindow and not showAnotherWindow:
      win.shouldClose = true # End program

    if showWindowDelay > 0:
      dec showWindowDelay
    else:
      once: # Avoid flickering screen at startup.
        win.show()

    #### end while

#---------------------
# Load title bar icon
#---------------------
proc loadTileBarIcon*(win: Window, iconName: string) =
  let handle = win.getHandle()
  if iconName.fileExists:
    var
      w, h: int
      channels: int
      pixels: seq[byte]
    pixels = stbi.load(iconName, w, h, channels, stbi.RGBA)
    var img = glfw.IconImageObj(width: w.int32, height: h.int32
      , pixels: cast[ptr uint8](pixels[0].addr))
    win.icons = [img]
  else:
    echo "loadTitleBarIcon(): Not found: ", iconName

#------
# main
#------
proc main() =
  glfw.initialize()
  var glfwWin: glfw.Window

  var cfg = DefaultOpenglWindowConfig
  const glsl_version = "#version 330" # GL 3.3
  cfg.version = glv33 # GL 3.3
  cfg.forwardCompat = true
  cfg.profile = opCoreProfile
  cfg.resizable = true
  if TransparentViewport:
    cfg.visible = false

  when defined(linux) and not defined(android): # For WSL2: WSLg
    cfg.contextCreationApi = ccaEglContextApi

  cfg.visible = false # See show()
  cfg.size = (w: MainWinWidth, h: MainWinHeight)
  cfg.title = "Dear ImGui + glfw + OpenGL"
  glfwWin = newWindow(cfg)
  if glfwWin.isNil:
    echo "Error!: GLFW create window"
    quit 1

  glfw.makeContextCurrent(glfwWin)
  defer: glfwWin.destroy()

  if not gladLoadGL(cast[proc(name: cstring): pointer {.cdecl.}](glfw.getProcAddress)):
    echo "Error!: initializing OpenGL"
    quit 1

  glfw.swapInterval(1) # Enable vsync

  #---------------------
  # Load title bar icon
  #---------------------
  var IconName = joinPath(os.getAppDir(), "res/img/n.png")
  loadTileBarIcon(glfwWin, IconName)

  # Setup ImGui
  let context = igCreateContext(nil)
  defer: context.igDestroyContext()
  if fDocking:
    var pio = igGetIO()
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  # GLFW + OpenGL
  doAssert ImGui_ImplGlfw_InitForOpenGL(cast[ptr impl_glfw.GLFWwindow](glfwwin.getHandle()), true)
  defer: ImGui_ImplGlfw_Shutdown()
  doAssert ImGui_ImplOpenGL3_Init(glsl_version)
  defer: ImGui_ImplOpenGL3_Shutdown()

  glfwWin.gui_main()

#------
# main
#------
main()
