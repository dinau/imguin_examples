import std/[os, strutils, parsecfg, parseutils]

# SDL2 settings
when defined(windows):
  const sdlPath = "../utils/sdl/SDL2/x86_64-w64-mingw32" # for windows10 or later
  {.passC:"-I" & sdlPath & "/include/SDL2".}
  {.passC:"-I" & sdlPath & "/include/SDL2/include".}
else: # for linux Debian 11 Bullseye or later
  {.passC:"-I/usr/include/SDL2".}
  {.passL:"-lSDL2".}
#

import sdl2_nim/sdl
export sdl

import imguin/[glad/gl, cimgui, sdl2_renderer, simple]
export              gl, cimgui, sdl2_renderer, simple

import ../utils/sdlrenderer/[zoomglass, sdl2/loadImage]
export zoomglass, loadImage
import ../utils/[saveImage, setupFonts, utils, vecs]
export saveImage, setupFonts, utils, vecs

type IniData = object
  clearColor*: ccolor
  startupPosX*, startupPosY*:cint
  viewportWidth*, viewportHeight*:cint

type WindowSdl* = object
  handle*: sdl.Window
  context*: ptr ImGuiContext
  renderer*: sdl.Renderer
  imnodes*:bool
  implot*:bool
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
proc createImGui*(w,h: cint, imnodes:bool = false, implot:bool = false, title:string="ImGui window"): WindowSdl =
  if sdl.init(sdl.InitVideo or sdl.InitTimer or sdl.InitGameController) != 0:
    echo "ERROR: Can't initialize SDL: ", sdl.getError()
    quit -1
  result.ini.viewportWidth = w
  result.ini.viewportHeight = h
  result.loadIni()

  # Basic IME support. App needs to call 'SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");'
  # before SDL_CreateWindow()!.
  discard sdl.setHint("SDL_HINT_IME_SHOW_UI", "1") # SDL2: must be v2.0.18 or later

  # Initialy main window is hidden.  See: showWindowDelay
  var flags:cuint = WINDOW_HIDDEN or WINDOW_OPENGL or WINDOW_RESIZABLE or WINDOW_ALLOW_HIGHDPI
  var window = sdl.createWindow( title
                               , result.ini.startupPosX, result.ini.startupPosY
                               , result.ini.viewportWidth, result.ini.viewportHeight, flags)
  if isNil window:
    echo "Fail to create window: ", sdl.getError()
    quit -1
  result.renderer = sdl.createRenderer(window, -1, sdl.RENDERER_PRESENTVSYNC or  sdl.RENDERER_ACCELERATED)
  if isNil result.renderer:
    echo "Error creating SDL_Renderer!"
    quit -1;

  # Setup ImGui
  result.context = igCreateContext(nil)
  if imnodes: # setup ImNodes
    result.imnodes = imnodes
    when defined(ImNodesEnable):
      imnodes_CreateContext()
  if implot: # setup ImPlot
    result.implot = implot
    when defined(ImPlotEnable):
      result.imPlotContext = ImPlot_CreateContext()

  if fDocking:
    var pio = igGetIO()
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  # Setup Platform/Renderer backends
  ImGui_ImplSDL2_InitForSDLRenderer(cast[ptr SDL_Window](window), cast[ptr SDL_renderer](result.renderer))
  ImGui_ImplSDLRenderer2_Init(cast[ptr SDL_Renderer](result.renderer))

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

    discard sdl.renderSetScale(win.renderer, pio.DisplayFramebufferScale.x, pio.DisplayFramebufferScale.y)
    discard sdl.setRenderDrawColor(win.renderer
                                , (win.ini.clearColor.elm.x * 255).uint8
                                , (win.ini.clearColor.elm.y * 255).uint8
                                , (win.ini.clearColor.elm.z * 255).uint8
                                , (win.ini.clearColor.elm.w * 255).uint8)
    discard sdl.renderClear(win.renderer)
    ImGui_ImplSDLRenderer2_RenderDrawData(cast[ptr impl_sdlrenderer2.ImDrawData](igGetDrawData()), cast[ptr SDL_Renderer](win.renderer))
    sdl.renderPresent(win.renderer);

    #if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
    ##  var backup_current_window = sdl.glGetCurrentWindow()
    #  var backup_current_context = sdl.glGetCurrentContext()
    #  igUpdatePlatformWindows()
    #  igRenderPlatformWindowsDefault(nil, nil)
    #  discard sdl.glmakeCurrent(backup_current_window,backup_current_context)

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
  ImGui_ImplSDLRenderer2_Shutdown()
  ImGui_ImplSdl2_Shutdown()
  when defined(ImPlotEnable):
    if win.implot:
      win.imPlotContext.ImPlotDestroyContext()
  when defined(ImNodesEnable):
    if win.imnodes:
      imnodes_DestroyContext(nil)
  igDestroyContext(nil)
  sdl.destroyRenderer(win.renderer)
  sdl.destroyWindow(win.handle)
  sdl.quit()

#----------
# newFrame
#----------
proc newFrame*() =
  ImGui_ImplSDLRenderer2_NewFrame()
  ImGui_ImplSdl2_NewFrame()
  igNewFrame()

proc getFrontendVersionString*(): string =
  var ver:sdl.Version
  sdl.getVersion(ver.addr)
  "SDL2 v$#.$#.$#" % [$ver.major.int,$ver.minor.int,$ver.patch.int]

proc getBackendVersionString*(): string = getFrontendVersionString() & " (Backend)"

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
