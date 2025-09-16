import std/[os, strutils, parsecfg, parseutils, strformat]

# SDL2 settings
when defined(windows):
  const sdlPath = "../libs/SDL2/x86_64-w64-mingw32" #
  {.passC:"-I" & sdlPath & "/include/SDL2".}
  {.passC:"-I" & sdlPath & "/include".}
  {.passL:"-L" & sdlPath & "/lib".}
else: # for linux Debian 11 Bullseye or later
  {.passC:"-I/usr/include/SDL2".}
#
import sdl2_nim/sdl
export sdl

import imguin/[glad/gl, cimgui, sdl2_opengl, simple]
export gl, cimgui, sdl2_opengl, simple

import ../utils/opengl/[zoomglass, loadImage]
export                  zoomglass, loadImage
import ../utils/[saveImage, setupFonts, utils, vecs]
export           saveImage, setupFonts, utils, vecs

type IniData = object
  clearColor*: ccolor
  startupPosX*, startupPosY*:cint
  viewportWidth*, viewportHeight*:cint

type WindowSdl* = object
  handle*: sdl.Window
  clearColor*: ccolor
  context*: ptr ImGuiContext
  glContext*: sdl.GLContext
  implotContext: ptr ImPlotContext
  showWindowDelay:int
  ini*:IniData

#--- Forward definitions
proc loadIni*(this: var WindowSdl)
proc saveIni*(this: var WindowSdl)

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

#-------------
# createImGui
#-------------
proc createImGui*(w,h: cint, title:string="ImGui window"): WindowSdl =
  if sdl.init(sdl.InitVideo or sdl.InitTimer or sdl.InitGameController) != 0:
    echo "ERROR: Can't initialize SDL: ", sdl.getError()
    quit -1
  result.ini.viewportWidth = w
  result.ini.viewportHeight = h
  result.loadIni()
  #
  var window:Window
  var glsl_version:string
  when defined(windows):
    const versions = [[4, 4], [4, 3], [4, 2], [4, 1], [4, 0], [3, 3]] # [4, 5] doesn't work well on Windows OS.
  else:
    const versions = [[3, 3]]
  for ver in versions:
    let major = ver[0].int32
    let minor = ver[1].int32
    discard sdl.glSetAttribute(GLattr.GL_CONTEXT_FLAGS, 0)
    discard sdl.glSetAttribute(GLattr.GL_CONTEXT_PROFILE_MASK, GL_CONTEXT_PROFILE_CORE)
    discard sdl.glSetAttribute(GLattr.GL_CONTEXT_MAJOR_VERSION, major)
    discard sdl.glSetAttribute(GLattr.GL_CONTEXT_MINOR_VERSION, minor)

    # Basic IME support. App needs to call 'SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");'
    # before SDL_CreateWindow()!.
    discard sdl.setHint("SDL_HINT_IME_SHOW_UI", "1") # SDL2: must be v2.0.18 or later

    discard sdl.glSetAttribute(GLattr.GL_DOUBLEBUFFER, 1)
    discard sdl.glSetAttribute(GLattr.GL_DEPTH_SIZE, 24)
    discard sdl.glSetAttribute(GLattr.GL_STENCIL_SIZE, 8)

    # Initialy main window is hidden.  See: showWindowDelay
    var flags:cuint = WINDOW_HIDDEN or WINDOW_OPENGL or WINDOW_RESIZABLE or WINDOW_ALLOW_HIGHDPI
    window = sdl.createWindow( title
                                 , result.ini.startupPosX, result.ini.startupPosY
                                 , result.ini.viewportWidth, result.ini.viewportHeight, flags)
    glsl_version = fmt"#version {major * 100 + minor * 10}"
    if not window.isNil:
      break

  if isNil window:
    echo "Fail to create window: ", sdl.getError()
    quit -1
  result.glContext = glCreateContext(window)
  discard glMakeCurrent(window, result.glContext);
  discard glSetSwapInterval(1)

  if not gladLoadGL(glGetProcAddress):
    sdl.log("opengl version: ", glGetString(GL_VERSION))
    quit "Error initialising OpenGL"

  # Setup ImGui
  result.context = igCreateContext(nil)

  if fDocking:
    var pio = igGetIO()
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  # GLFW + OpenGL
  doAssert ImGui_ImplSdl2_InitForOpenGL(cast[ptr SDL_Window](window) , result.glContext)
  doAssert ImGui_ImplOpenGL3_Init(glsl_version.cstring)

  if TransparentViewport:
    result.ini.clearColor = ccolor(elm:(x:0f, y:0f, z:0f, w:0.0f)) # Transparent
  result.handle = window

  setTheme(Classic)

  discard setupFonts() # Add multibytes font

  result.showWindowDelay = 2 # TODO

#--------
# render
#--------
proc render*(win: var WindowSdl) =
    var pio = igGetIO()
    igRender()
    glViewport(0, 0, (pio.DisplaySize.x).GLsizei, (pio.DisplaySize.y).GLsizei)
    glClearColor(win.ini.clearColor.elm.x, win.ini.clearColor.elm.y, win.ini.clearColor.elm.z, win.ini.clearColor.elm.w)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())

    if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
      var backup_current_window = sdl.glGetCurrentWindow()
      var backup_current_context = sdl.glGetCurrentContext()
      igUpdatePlatformWindows()
      igRenderPlatformWindowsDefault(nil, nil)
      discard sdl.glmakeCurrent(backup_current_window,backup_current_context)

    sdl.glSwapWindow(win.handle)

    if win.showWindowDelay > 0:
      dec win.showWindowDelay
    else:
      once: # Avoid flickering screen at startup.
        win.handle.showWindow()

#--------------
# destroyImGui
#--------------
proc destroyImGui*(win: var WindowSdl) =
  win.saveIni()
  ImGui_ImplOpenGL3_Shutdown()
  ImGui_ImplSdl2_Shutdown()
  igDestroyContext(nil)
  sdl.glDeleteContext(win.context)
  sdl.destroyWindow(win.handle)
  sdl.quit()

#----------------
# isIconifySleep
#----------------
proc isIconifySleep*(win:WindowSdl): bool =
  if 0 != (sdl.getWindowFlags(win.handle) and sdl.WindowMinimized):
    sdl.delay(10)
    return true

#----------
# newFrame
#----------
proc newFrame*() =
  ImGui_ImplOpenGL3_NewFrame()
  ImGui_ImplSdl2_NewFrame()
  igNewFrame()

proc getFrontendVersionString*(): string =
  var ver:sdl.Version
  sdl.getVersion(ver.addr)
  "SDL2 v$#.$#.$#" % [$ver.major.int,$ver.minor.int,$ver.patch.int]

proc getBackendVersionString*(): string = fmt"OpenGL v{($cast[cstring](glGetString(GL_VERSION))).split[0]} (Backend)"

#---------------
# setClearcolor
#---------------
proc setClearColor*(win: var WindowSdl, col: ccolor) =
  win.ini.clearColor = col

#------
# free
#------
proc free*(mem: pointer) {.importc,header:"<stdlib.h>".}

# Sections (Cat.)
const scWindow           = "Window"
# [Window]
const startupPosX      = "startupPosX"
const startupPosY      = "startupPosY"
const viewportWidth    = "viewportWidth"
const viewportHeight   = "viewportHeigth"
const colBGx = "colBGx"
const colBGy = "colBGy"
const colBGz = "colBGz"
const colBGw = "colBGw"

#---------
# loadIni    --- Load ini
#---------
proc loadIni*(this: var WindowSdl) =
  let iniName = getAppFilename().changeFileExt("ini")
  #----------
  # Load ini
  #----------
  if fileExists(iniName):
    let cfg = loadConfig(iniName)
    # Windows
    this.ini.startupPosX = cfg.getSectionValue(scWindow,startupPosX).parseInt.int32
    if 10 > this.ini.startupPosX: this.ini.startupPosX = 10
    this.ini.startupPosY = cfg.getSectionValue(scWindow,startupPosY).parseInt.int32
    if 10 > this.ini.startupPosY: this.ini.startupPosY = 10
    this.ini.viewportWidth = cfg.getSectionValue(scWindow,viewportWidth).parseInt.cint
    if this.ini.viewportWidth < 100: this.ini.viewportWidth = 900
    this.ini.viewportHeight = cfg.getSectionValue(scWindow,viewportHeight).parseInt.cint
    if this.ini.viewportHeight < 100: this.ini.viewportHeight = 900
    var fval:float
    discard parsefloat(cfg.getSectionValue(scWindow, colBGx, "0.25"), fval)
    this.ini.clearColor.elm.x = fval.cfloat
    discard parsefloat(cfg.getSectionValue(scWindow, colBGy, "0.65"), fval)
    this.ini.clearColor.elm.y = fval.cfloat
    discard parsefloat(cfg.getSectionValue(scWindow, colBGz, "0.85"), fval)
    this.ini.clearColor.elm.z = fval.cfloat
    discard parsefloat(cfg.getSectionValue(scWindow, colBGw, "1.00"), fval)
    this.ini.clearColor.elm.w = fval.cfloat
  #----------------
  # Set first defaults
  #----------------
  else:
    this.ini.startupPosX = 100
    this.ini.startupPosY = 200
    this.ini.clearColor = ccolor(elm:(x:0.25f, y:0.65f, z:0.85f, w:1.0f))

#---------
# saveIni   --- save iniFile
#---------
proc saveIni*(this: var WindowSdl) =
  let iniName = getAppFilename().changeFileExt("ini")
  var ini = newConfig()
  var x,y: cint
  this.handle.getwindowPosition(addr x, addr y)
  this.ini.startupPosX = x
  this.ini.startupPosY = y
  ini.setSectionKey(scWindow,startupPosX,$this.ini.startupPosX)
  ini.setSectionKey(scWindow,startupPosY,$this.ini.startupPosY)
  let ws = igGetMainViewPort().WorkSize
  ini.setSectionKey(scWindow, viewportWidth,$ws.x.cint)
  ini.setSectionKey(scWindow, viewportHeight,$ws.y.cint)
  ini.setSectionKey(scWindow, colBGx, $this.ini.clearColor.elm.x)
  ini.setSectionKey(scWindow, colBGy, $this.ini.clearColor.elm.y)
  ini.setSectionKey(scWindow, colBGz, $this.ini.clearColor.elm.z)
  ini.setSectionKey(scWindow, colBGw, $this.ini.clearColor.elm.w)
  # save ini file
  writeFile(iniName,$ini)
