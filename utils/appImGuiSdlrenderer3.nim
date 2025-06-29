import std/[os, strutils, parsecfg, parseutils]

# SDL3 settings
when defined(windows):
  const sdlPath = "../utils/sdl/SDL3/x86_64-w64-mingw32"
  {.passC:"-I" & sdlPath & "/include".}
  {.passC:"-I" & sdlPath & "/include/SDL3".}
  {.passL:"-L" & sdlPath & "/lib".}
#  when defined(vcc): # Fail: TODO
#    {.passC:"libSDL3.dll.a".}
#    {.passL:"/LIBPATH:" & sdl3LibPath.}
when defined(linux): # for linux Debian 11 Bullseye or later
  {.passC:"-I/usr/include/SDL3".}

import sdl3_nim
export sdl3_nim

import imguin/[glad/gl, sdl3_renderer, cimgui, simple]
export              gl, sdl3_renderer, cimgui, simple

import ../utils/sdlrenderer/[zoomglass, sdl3/loadImage]
export                       zoomglass,      loadImage
import ../utils/[saveImage, setupFonts, utils, vecs]
export           saveImage, setupFonts, utils, vecs

type IniData = object
  clearColor*: ccolor
  startupPosX*, startupPosY*:cint
  viewportWidth*, viewportHeight*:cint

type WindowSdl* = object
  handle*: ptr SDL_Window
  context*: ptr ImGuiContext
  renderer*: ptr SDL_Renderer
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
 fDocking = false
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
proc createImGui*(w,h: cint, imnodes:bool = false, implot:bool = false, title:string="ImGui window SDL3 renderer"): WindowSdl =
  if not SDL_Init(SDL_INIT_VIDEO or SDL_INIT_GAMEPAD):
    echo "\nError!: SDL_Init()"

  result.ini.viewportWidth = w
  result.ini.viewportHeight = h
  result.loadIni()

  const SDL_WINDOW_RESIZABLE = 0x0000000000000020'u64
  const SDL_WINDOW_OPENGL    = 0x0000000000000002'u64
  const SDL_WINDOW_HIDDEN    = 0x0000000000000008'u64
  var flags = SDL_WINDOW_RESIZABLE or SDL_WINDOW_OPENGL or SDL_WINDOW_HIDDEN
  var window = SDL_CreateWindow(title
                               , result.ini.viewportWidth , result.ini.viewportHeight
                               , flags.SDL_WindowFlags)
  if isNil window:
    echo "Error!: SDL_CreateWindow()"
    quit 1

  result.renderer = SDL_CreateRenderer(window, nil)
  SDL_SetRenderVSync(result.renderer, 1);
  if isNil result.renderer:
    quit -1

  const SDL_WINDOWPOS_CENTERED = cast[cuint](805240832'i64)
  SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED.cint, SDL_WINDOWPOS_CENTERED.cint)

  # Setup ImGui
  result.context = igCreateContext(nil)
  if isNIl result.context:
    echo "Error!: igCreateContext()"
  if imnodes: # setup ImNodes
    result.imnodes = imnodes
    when defined(ImNodesEnable):
      imnodes_CreateContext()
  if implot: # setup ImPlot
    result.implot = implot
    when defined(ImPlotEnable):
      result.imPlotContext = ImPlot_CreateContext()

  var pio = igGetIO()
  pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_NavEnableKeyboard.cint
  pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_NavEnableGamepad.cint
  if fDocking:
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
    #pio.ConfigViewports_NoAutomerge = true

  #igStyleColorsDark(nil)
  igStyleColorsClassic(nil)

  var style = igGetStyle()
  if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
    style.WindowRounding = 0.0f;
    style.Colors[ImGuiCol_WindowBg.int].w = 1.0f

  if not ImGui_ImplSdl3_InitForSDLRenderer(window, result.renderer):
    echo "Error!: ImGui_ImplSdl3_InitForOpenGL()"
  if not ImGui_ImplSDLRenderer3_Init(cast[ptr SDL_Renderer](result.renderer)):
    echo "Error!: ImGui_ImplOpenGL3_Init()"

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
    SDL_SetRenderScale(win.renderer, pio.DisplayFramebufferScale.x, pio.DisplayFramebufferScale.y)
    SDL_SetRenderDrawColor(win.renderer
                                , (win.ini.clearColor.elm.x * 255).uint8
                                , (win.ini.clearColor.elm.y * 255).uint8
                                , (win.ini.clearColor.elm.z * 255).uint8
                                , (win.ini.clearColor.elm.w * 255).uint8)
    SDl_RenderClear(win.renderer)
    ImGui_ImplSDLRenderer3_RenderDrawData(cast[ptr impl_sdlrenderer3.ImDrawData](igGetDrawData()), cast[ptr SDL_Renderer](win.renderer))
    SDL_RenderPresent(win.renderer)

    if win.showWindowDelay > 0:
      dec win.showWindowDelay
    else:
      once: # Avoid flickering screen at startup.
        win.handle.SDL_ShowWindow()

#--------------
# destroyImGui
#--------------
proc destroyImGui*(win: var WindowSdl) =
  win.saveIni()
  ImGui_ImplSDLRenderer3_Shutdown()
  ImGui_ImplSdl3_Shutdown()
  when defined(ImPlotEnable):
    if win.implot:
      win.imPlotContext.ImPlotDestroyContext()
  when defined(ImNodesEnable):
    if win.imnodes:
      imnodes_DestroyContext(nil)
  igDestroyContext(win.context)
  SDL_DestroyRenderer(win.renderer)
  SDL_destroyWindow(win.handle)
  SDL_quit_proc()

#----------------
# isIconifySleep
#----------------
proc isIconifySleep*(win:WindowSdl): bool =
  const SDL_WINDOW_MINIMIZED = 0x0000000000000040'u64
  if 0 != (SDL_GetWindowFlags(win.handle) and SDL_WINDOW_MINIMIZED):
    SDL_Delay(10)
    return true

#----------
# newFrame
#----------
proc newFrame*() =
  ImGui_ImplSDLRenderer3_NewFrame()
  ImGui_ImplSdl3_NewFrame()
  igNewFrame()

proc getFrontendVersionString*(): string =
  let ver =  SDL_getVersion() # == cint
  return "SDL3 v$#.$#" % [$ver, $SDL_GetRevision()]

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
  this.handle.SDL_GetwindowPosition(addr x, addr y)
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
