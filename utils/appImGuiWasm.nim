import std/[strformat]
import imguin/[cimgui, impl_glfw, impl_opengl, simple]
export cimgui, simple
import ../utils/[utils, setupFonts, togglebutton, vecs]
import staticglfw as wglfw
import stb_image/read as stbi

type IniData = object
  clearColor*: ccolor
  startupPosX*, startupPosY*: cint
  viewportWidth*, viewportHeight*: cint
  imageSaveFormatIndex*: int
  theme: Theme

type AppWindow* = object
  glfwWin*: wglfw.Window
  context*: ptr ImGuiContext
  implotContext: ptr ImPlotContext
  implot3dContext: ptr ImPlot3dContext
  showWindowDelay: int # Avoid flickering screen at startup.
  ini*: IniData

# OpenGL header selection:
# Emscripten uses WebGL which is based on OpenGL ES2/ES3.
# For desktop builds, use the standard OpenGL header.
import opengl
export opengl
when not defined(emscripten):
  import std/[os, strutils]
  proc loadTitleBarIcon(win: AppWindow, iconName: string)

proc setTheme*(win: var AppWindow, theme: Theme): string{.discardable.}

#-------------
# shouldClose
#-------------
proc shouldClose*(win: AppWindow): bool =
  return 1 == wglfw.windowshouldClose(win.glfwWin).cint

proc `shouldClose=`*(win: AppWindow, state: bool) =
  wglfw.setWindowshouldClose(win.glfwWin, state.cint)

#----------------------------
# Emscripten main loop helper
#----------------------------
# In C++ the original uses std::function + lambda.
# In Nim/C we use a global callback proc pointer instead.
when defined(emscripten):
  proc emscripten_set_main_loop(f: proc() {.cdecl.}, fps: cint, simulate_infinite_loop: cint) {.importc, header: "<emscripten/emscripten.h>".}

  var g_MainLoopCallback: proc() {.cdecl.}

  proc emscriptenMainLoop() {.cdecl.} =
    if g_MainLoopCallback != nil:
      g_MainLoopCallback()

  template emscriptenMainloopBegin*(window: untyped, body: untyped) =
    var loopBody {.global.}: proc() {.cdecl.}
    loopBody = proc() {.cdecl.} =
      body
    g_MainLoopCallback = loopBody
    emscripten_set_main_loop(emscriptenMainLoop, 0, 1)

else:
  # Desktop: just a regular while loop
  template emscriptenMainloopBegin*(window: untyped, body: untyped) =
    while not shouldClose(window):
      body

#------------------------------------
# Error callback
#------------------------------------
proc glfwErrorCallback(error: int32, description: cstring) {.cdecl.} =
  echo fmt"GLFW Error {error}: {description}"

#--- Must be global variable at this place ---
var
  pio: ptr ImGuiIO
  main_scale: cfloat
  backup_current_context: wglfw.Window

#------
# main
#------
proc createImGui*(w: cint = 1024, h: cint = 900, title: string = "ImGui window", docking: bool = true): AppWindow =
  discard wglfw.setErrorCallback(glfwErrorCallback)

  if wglfw.init() == 0:
    quit(-1)

  # Decide GL+GLSL versions
  when defined(emscripten):
    when defined(OPENGL_ES3):
      # GL ES 3.0 + GLSL 300 es (WebGL 2.0)
      let glsl_version = "#version 300 es";
      wglfw.windowHint(wglfw.CONTEXT_VERSION_MAJOR, 3);
      wglfw.windowHint(wglfw.CONTEXT_VERSION_MINOR, 0);
      wglfw.windowHint(wglfw.CLIENT_API, wglfw.OPENGL_ES_API);
    else:
      # GL ES 2.0 + GLSL 100 (WebGL via Emscripten)
      let glsl_version = "#version 100"
      wglfw.windowHint(wglfw.ContextVersionMajor.int32, 2)
      wglfw.windowHint(wglfw.ContextVersionMinor.int32, 0)
      wglfw.windowHint(wglfw.ClientApi.int32, wglfw.OpenglEsApi.int32)
  elif defined(macosx):
    # GL 3.2 Core + GLSL 150
    let glsl_version = "#version 150"
    wglfw.windowHint(wglfw.OpenglForwardCompat.int32, 1)
    wglfw.windowHint(wglfw.OpenglProfile.int32, wglfw.OpenglCoreProfile.int32)
    wglfw.windowHint(wglfw.ContextVersionMajor.int32, 3)
    wglfw.windowHint(wglfw.ContextVersionMinor.int32, 2)
  else:
    # GL 3.2 + GLSL 130
    let glsl_version = "#version 130"
    wglfw.windowHint(wglfw.OpenglForwardCompat.int32, 1)
    wglfw.windowHint(wglfw.OpenglProfile.int32, wglfw.OpenglCoreProfile.int32)
    wglfw.windowHint(wglfw.ContextVersionMajor.int32, 3)
    wglfw.windowHint(wglfw.ContextVersionMinor.int32, 2)

  # just an extra window hint for resize
  wglfw.windowHint(wglfw.Resizable.int32, wglfw.True)
  # Hide window
  wglfw.windowHint(wglfw.Visible.int32, wglfw.False)

  main_scale = ImGui_ImplGlfw_GetContentScaleForMonitor(cast[ptr GlfwMonitor](wglfw.getPrimaryMonitor())) # Valid on GLFW 3.3+ only
  #---------------
  # Create Window
  #---------------
  result.glfwwin = wglfw.createWindow(
    (w.cfloat * main_scale).int32,
    (h.cfloat * main_scale).int32,
    title, nil, nil)
  if result.glfwwin == nil:
    echo "Error!: Failed to create window! Terminating!"
    wglfw.terminate()
    quit(-1)

  wglfw.makeContextCurrent(result.glfwwin)

  # enable vsync
  wglfw.swapInterval(1)

  when not defined(emscripten):
    #---------------------
    # Load title bar icon
    #---------------------
    var IconName = os.joinPath(os.getAppDir(), "res/img/n.png")
    loadTitleBarIcon(result, IconName)

    # check opengl version (desktop only, no glGetString in ES2 context before init)
    opengl.loadExtensions()

  # setup imgui
  igCreateContext(nil)

  # set docking
  pio = igGetIO_Nil()
  pio.ConfigFlags = pio.ConfigFlags or
    ImGui_ConfigFlags_NavEnableKeyboard.cint or
    ImGui_ConfigFlags_NavEnableGamepad.cint
  # ImGuiConfigFlags_DockingEnable.cint      # Enable Docking
  # pio.ConfigFlags = pio.ConfigFlags or ImGuiConfigFlags_ViewportsEnable.cint  # Web
  # pio.ConfigViewportsNoAutoMerge = true;
  # pio.ConfigViewportsNoTaskBarIcon = true;

  # For an Emscripten build we are disabling file-system access, so let's not
  # attempt to do a fopen() of the imgui.ini file.
  # You may manually call LoadIniSettingsFromMemory() to load settings from your own storage.
  when defined(emscripten):
    pio.IniFilename = nil

  #igStyleColorsDark(nil)
  #igStyleColorsLight(nil)
  #igStyleColorsClassic(nil)

  # Setup scaling
  let style = igGetStyle()
  style.ImGuiStyle_ScaleAllSizes(main_scale) # Bake a fixed style scale. (until we have a solution for dynamic style scaling, changing this requires resetting Style + calling this again)
  style.FontScaleDpi = main_scale # Set initial font scale. (using io.ConfigDpiScaleFonts=true makes this unnecessary. We leave both here for documentation purpose)
  # GLFW >= 3.4
  pio.ConfigDpiScaleFonts = true # [Experimental] Automatically overwrite style.FontScaleDpi in Begin() when Monitor DPI changes. This will scale fonts but _NOT_ scale sizes/padding for now.
  pio.ConfigDpiScaleViewports = true # [Experimental] Scale Dear ImGui and Platform Windows when Monitor DPI changes.

  # WindowRounding
  style.WindowRounding = 5.0


  ImGui_ImplGlfw_InitForOpenGL(cast[ptr GlfwWindow](result.glfwwin), true)
  when defined(emscripten):
    ImGui_ImplGlfw_InstallEmscriptenCallbacks(cast[ptr Glfwwindow](result.glfwwin), "#canvas")
  ImGui_ImplOpenGL3_Init(glsl_version.cstring)

  result.ini.clearColor = ccolor(elm: (x: 0.25f, y: 0.65f, z: 0.85f, w: 1.0f))

  result.showWindowDelay = 1

#----------
# newFrame
#----------
proc newFrame*() =
  ImGui_ImplOpenGL3_NewFrame()
  ImGui_ImplGlfw_NewFrame()
  igNewFrame()

#----------------
# pollEvents
#----------------
proc pollEvents*(win: AppWindow) =
  when defined(emscripten):
    wglfw.pollEvents() # timeout == 0  # Use standard PollEvents()
  else:
    wglfw.waitEventsTimeout(1.0 / 60.0) # Reduce CPU load

proc pollEvents*(win: AppWindow, timeout: float) =
  when defined(emscripten):
    wglfw.pollEvents() # timeout == 0  # Use standard PollEvents()
  else:
    if timeout != 0:
      wglfw.waitEventsTimeout(timeout) # Sepcify CPU perofrmance
    else:
      wglfw.pollEvents() # timeout == 0  # Use standard PollEvents()

#----------------
# isIconifySleep
#----------------
proc isIconifySleep*(win: AppWindow): bool =
  if 0 != win.glfwWin.getWindowAttrib(ICONIFIED):
    ImGui_ImplGlfw_Sleep(10)
    return true

var
  dispW: cint
  dispH: cint
 #--------
 # render
 #--------
proc render*(win: var AppWindow) =
  igRender()
  wglfw.getFrameBufferSize(win.glfwWin, addr dispW, addr dispH)
  glViewport(0, 0, dispW.cint, dispH.cint)
  glClearColor(win.ini.clearColor.elm.x, win.ini.clearColor.elm.y, win.ini.clearColor.elm.z, win.ini.clearColor.elm.w)
  glClear(GL_COLOR_BUFFER_BIT)
  ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())
  if 0 != (pio.ConfigFlags.cint and ImGuiConfigFlags_ViewportsEnable.cint):
    backup_current_context = wglfw.getCurrentContext()
    igUpdatePlatformWindows()
    igRenderPlatformWindowsDefault(nil, nil)
    wglfw.makeContextCurrent(backup_current_context)

  wglfw.swapBuffers(win.glfwWin)

  if win.showWindowDelay > 0:
    dec win.showWindowDelay
  else:
    once: # Avoid flickering screen at startup.
      win.glfwWin.showWindow()

#--------------
# destroyImGui
#--------------
proc destroyImGui*(win: var AppWindow) =
  #win.saveIni()
  ImGui_ImplOpenGL3_Shutdown()
  ImGui_ImplGlfw_Shutdown()
  igDestroyContext(nil)
  win.glfwWin.destroyWindow()
  wglfw.terminate()

#----------
# setTheme
#----------
proc setTheme*(win: var AppWindow, theme: Theme): string =
  win.ini.theme = theme
  utils.setTheme(theme)
  return $theme

#----------
# getTheme
#----------
proc getTheme*(win: AppWindow): Theme =
  return win.ini.theme

proc getFrontendVersionString*(): string = fmt"GLFW v{$wglfw.getVersionString()}"
when defined(emscripten):
  proc getBackendVersionString*(): string = fmt"{$cast[cstring](glGetString(GL_VERSION))} (Backend)"
else:
  proc getBackendVersionString*(): string = fmt"OpenGL v{($cast[cstring](glGetString(GL_VERSION))).split[0]} (Backend)"

#---------------
# setClearcolor
#---------------
proc setClearColor*(win: var AppWindow, col: ccolor) =
  win.ini.clearColor = col

#---------------------
# Load title bar icon
#---------------------
when not defined(emscripten):
  proc loadTitleBarIcon(win: AppWindow, iconName: string) =
    if iconName.fileExists:
      var
        w, h: int
        channels: int
        pixels: seq[byte]
      pixels = stbi.load(iconName, w, h, channels, stbi.RGBA)
      var img = wglfw.GlfwImage(width: w.int32, height: h.int32
        , pixels: cast[cstring](pixels[0].addr))
      win.glfwWin.setWindowicon(1, addr img)
    else:
      echo "loadTitleBarIcon(): Not found: ", iconName
      #win.glfwWin.icons = []

#------------
# infoWindow
#------------
proc infoWindow*(win: var AppWindow, pos: Vec2 = vec2(0, 0)) =
  var
    sw{.global.}: bool
    strSw{.global.}: string
  once:
    let theme = win.getTheme()
    sw = if theme == Theme.Classic: false else: true
    strSw = $theme

  igShowDemoWindow(nil)

  block:
    igSetNextWindowPos(pos, ImGui_Cond_FirstUseEver.cint, vec2(0, 0))
    igBegin("Info window " & ICON_FA_DOG, nil, 0)
    defer: igEnd()
    if igToggleButton(strSw, sw):
      if sw:
        strSw = win.setTheme(Dark)
      else:
        strSw = win.setTheme(Classic)
    #
    igText((ICON_FA_COMMENT & " " & getFrontendVersionString()).cstring)
    igText((ICON_FA_COMMENT_SMS & " " & getBackendVersionString()).cstring)
    igText("%s %s", ICON_FA_COMMENT_DOTS & " Dear ImGui", igGetVersion())
    igText("%s%s", ICON_FA_COMMENT_MEDICAL & " Nim-", NimVersion)
    igColorEdit3("Background color", win.ini.clearColor.array3, 0.ImGuiColorEditFlags)
    igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, igGetIO().Framerate.cfloat)
