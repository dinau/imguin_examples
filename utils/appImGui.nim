import std/[os, strutils, parsecfg, parseutils, strformat]

import nimgl/[opengl, glfw]
export        opengl, glfw

import imguin/[cimgui,glfw_opengl, simple]
export         cimgui,glfw_opengl, simple

import ../utils/opengl/[zoomglass, loadImage]
export                  zoomglass, loadImage
import ../utils/[saveImage, setupFonts, utils, vecs]
export           saveImage, setupFonts, utils, vecs

type IniData = object
  clearColor*: ccolor
  startupPosX*, startupPosY*:cint
  viewportWidth*, viewportHeight*:cint
  imageSaveFormatIndex*:int
  theme:Theme

type Window* = object
  handle*: glfw.GLFWwindow
  context*: ptr ImGuiContext
  imnodes*:bool
  implot*:bool
  implot3d*:bool
  implotContext: ptr ImPlotContext
  implot3dContext: ptr ImPlot3dContext
  showWindowDelay:int
  ini*:IniData

#--- Forward definitions
proc loadIni*(this: var Window)
proc saveIni*(this: var Window)
proc setTheme*(this: var Window, theme:Theme): string

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


#-------------
# createImGui
#-------------
proc createImGui*(w:cint=1024, h:cint=900, imnodes:bool = false, implot:bool = false, implot3d=false, title:string="ImGui window", docking:bool=true): Window =
  doAssert glfwInit()
  result.ini.viewportWidth = w
  result.ini.viewportHeight = h
  result.loadIni()
  result.implot = implot
  result.implot3d = implot3d
  result.imnodes = imnodes
  if result.implot3d:
    result.implot = true

  var
    fDocking = docking
    fViewport = false
    TransparentViewport = false
  block:
    if TransparentViewport:
      fViewport = true
    if fViewport:
      fDocking = true

  var glfwWin: GLFWwindow
  var glsl_version:string
  when defined(windows):
    const versions = [[4, 4], [4, 3], [4, 2], [4, 1], [4, 0], [3, 3]] # [4, 5] or later doesn't work well on my Windows OS.
  else:
    const versions = [[3, 3]]

  for ver in versions:
    let major = ver[0].int32
    let minor = ver[1].int32
    if TransparentViewport:
      glfwWindowHint(GLFWVisible, GLFW_FALSE)

    glfwWindowHint(GLFWContextVersionMajor, major)
    glfwWindowHint(GLFWContextVersionMinor, minor)
    glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
    glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
    glfwWindowHint(GLFWResizable, GLFW_TRUE)
    #
    glfwWindowHint(GLFWVisible, GLFW_FALSE)
    glfwWin = glfwCreateWindow(result.ini.viewportWidth, result.ini.viewportHeight, title=title)
    glsl_version = fmt"#version {major * 100 + minor * 10}"
    if not glfwWin.isNil:
      echo "GLSL: ",glsl_version
      break

  if glfwWin.isNil:
    quit(-1)
  glfwWin.makeContextCurrent()

  setWindowPos(glfwWin, result.ini.startupPosX, result.ini.startupPosY)
  glfwSwapInterval(1) # Enable vsync

  #---------------------
  # Load title bar icon
  #---------------------
  var IconName = os.joinPath(os.getAppDir(),"res/img/n.png")
  LoadTileBarIcon(glfwWin, IconName)

  doAssert glInit() # OpenGL init

  # Setup ImGui
  result.context = igCreateContext(nil)
  if result.imnodes: # setup ImNodes
    when defined(ImNodesEnable):
      imnodes_CreateContext()

  if result.implot: # setup ImPlot
    when defined(ImPlotEnable) or defined(ImPlot) or defined(ImPlot3DEnable) or defined(ImPlot3D) :
      result.imPlotContext = ImPlot_CreateContext()
    else:
      echo "Fatal Error!: setup ImPlot: Specify option  -d:ImPlot"
      quit 1

  if result.implot3d: # setup ImPlot3D
    when defined(ImPlot3DEnable) or defined(ImPlot3D):
      result.imPlot3dContext = ImPlot3d_CreateContext()
    else:
      echo "Fatal Error!: setup ImPlot3D: Specify option  -d:ImPlot3DEnable"
      quit 1

  if fDocking:
    var pio = igGetIO()
    pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_DockingEnable.cint
    if fViewport:
      pio.ConfigFlags = pio.ConfigFlags or ImGui_ConfigFlags_ViewportsEnable.cint
      pio.ConfigViewports_NoAutomerge = true

  # GLFW + OpenGL
  doAssert ImGui_ImplGlfw_InitForOpenGL(cast[ptr GLFWwindow](glfwwin), true)
  doAssert ImGui_ImplOpenGL3_Init(glsl_version.cstring)

  if TransparentViewport:
    result.ini.clearColor = ccolor(elm:(x:0f, y:0f, z:0f, w:0.0f)) # Transparent
  result.handle = glfwWin

  setTheme(result.ini.theme)

  discard setupFonts() # Add multibytes font

  result.showWindowDelay = 2 # TODO

#--------
# render
#--------
proc render*(window: var Window) =
  igRender()
  glClearColor(window.ini.clearColor.elm.x, window.ini.clearColor.elm.y, window.ini.clearColor.elm.z, window.ini.clearColor.elm.w)
  glClear(GL_COLOR_BUFFER_BIT)
  ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())

  var pio = igGetIO()
  if 0 != (pio.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
    var backup_current_window = glfwGetCurrentContext()
    igUpdatePlatformWindows()
    igRenderPlatformWindowsDefault(nil, nil)
    backup_current_window.makeContextCurrent()

  window.handle.swapBuffers()

  if window.showWindowDelay > 0:
    dec window.showWindowDelay
  else:
    once: # Avoid flickering screen at startup.
      window.handle.showWindow()

#--------------
# destroyImGui
#--------------
proc destroyImGui*(window: var Window) =
  window.saveIni()
  ImGui_ImplOpenGL3_Shutdown()
  ImGui_ImplGlfw_Shutdown()
  when defined(ImPlotEnable) or defined(ImPlot):
    if window.implot:
      window.imPlotContext.ImPlotDestroyContext()
  when defined(ImPlot3DEnable) or defined(ImPlot3D):
    if window.implot3d:
      window.imPlot3dContext.ImPlot3dDestroyContext()
  when defined(ImNodesEnable):
    if window.imnodes:
      imnodes_DestroyContext(nil)
  window.context.igDestroyContext()
  window.handle.destroyWindow()
  glfwTerminate()

#----------
# newFrame
#----------
proc newFrame*() =
  ImGui_ImplOpenGL3_NewFrame()
  ImGui_ImplGlfw_NewFrame()
  igNewFrame()

proc getFrontendVersionString*(): string = fmt"GLFW v{$glfwGetVersionString()}"
proc getBackendVersionString*(): string = fmt"OpenGL v{($cast[cstring](glGetString(GL_VERSION))).split[0]} (Backend)"

#---------------
# setClearcolor
#---------------
proc setClearColor*(win: var Window, col: ccolor) =
  win.ini.clearColor = col

#------
# free
#------
proc free*(mem: pointer) {.importc,header:"<stdlib.h>".}

# Sections
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
const theme  = "theme"
# [Image]
const scImage           = "Image"
const imageSaveFormatIndex = "imageSaveFormatIndex"

#---------
# loadIni    --- Load ini
#---------
proc loadIni*(this: var Window) =
  let iniName = getAppFilename().changeFileExt("ini")
  #----------
  # Load ini
  #----------
  if fileExists(iniName):
    let cfg = loadConfig(iniName)
    # Window pos
    this.ini.startupPosX = cfg.getSectionValue(scWindow,startupPosX).parseInt.cint
    if 10 > this.ini.startupPosX: this.ini.startupPosX = 10
    this.ini.startupPosY = cfg.getSectionValue(scWindow,startupPosY).parseInt.cint
    if 10 > this.ini.startupPosY: this.ini.startupPosY = 10

    # Window size
    this.ini.viewportWidth = cfg.getSectionValue(scWindow,viewportWidth).parseInt.cint
    if this.ini.viewportWidth < 100: this.ini.viewportWidth = 900
    this.ini.viewportHeight = cfg.getSectionValue(scWindow,viewportHeight).parseInt.cint
    if this.ini.viewportHeight < 100: this.ini.viewportHeight = 900

    # Background color
    var fval:float
    discard parsefloat(cfg.getSectionValue(scWindow, colBGx, "0.25"), fval)
    this.ini.clearColor.elm.x = fval.cfloat
    discard parsefloat(cfg.getSectionValue(scWindow, colBGy, "0.65"), fval)
    this.ini.clearColor.elm.y = fval.cfloat
    discard parsefloat(cfg.getSectionValue(scWindow, colBGz, "0.85"), fval)
    this.ini.clearColor.elm.z = fval.cfloat
    discard parsefloat(cfg.getSectionValue(scWindow, colBGw, "1.00"), fval)
    this.ini.clearColor.elm.w = fval.cfloat

    # Image format index
    this.ini.imageSaveFormatIndex = cfg.getSectionValue(scImage,imageSaveFormatIndex).parseInt.cint

    # Theme
    this.ini.theme = cast[Theme](cfg.getSectionValue(scWindow,theme).parseInt)

  #----------------
  # Set first defaults
  #----------------
  else:
    this.ini.startupPosX = 100
    this.ini.startupPosY = 200
    this.ini.clearColor = ccolor(elm:(x:0.25f, y:0.65f, z:0.85f, w:1.0f))
    this.ini.imageSaveFormatIndex = 0
    this.ini.theme = Classic

#---------
# saveIni   --- save iniFile
#---------
proc saveIni*(this: var Window) =
  let iniName = getAppFilename().changeFileExt("ini")
  var ini = newConfig()
  # Window pos
  getWindowPos(this.handle, addr this.ini.startupPosX,addr this.ini.startupPosY)
  ini.setSectionKey(scWindow,startupPosX,$this.ini.startupPosX)
  ini.setSectionKey(scWindow,startupPosY,$this.ini.startupPosY)

  # Window size
  let ws = igGetMainViewPort().WorkSize
  ini.setSectionKey(scWindow, viewportWidth,$ws.x.cint)
  ini.setSectionKey(scWindow, viewportHeight,$ws.y.cint)

  # Background color
  ini.setSectionKey(scWindow, colBGx, $this.ini.clearColor.elm.x)
  ini.setSectionKey(scWindow, colBGy, $this.ini.clearColor.elm.y)
  ini.setSectionKey(scWindow, colBGz, $this.ini.clearColor.elm.z)
  ini.setSectionKey(scWindow, colBGw, $this.ini.clearColor.elm.w)

  # Image format index
  ini.setSectionKey(scImage, imageSaveFormatIndex, $this.ini.imageSaveFormatIndex)

  # Theme
  ini.setSectionKey(scWindow, theme, $this.ini.theme.int)

  # save ini file
  writeFile(iniName,$ini)

#----------
# setTheme
#----------
proc setTheme*(this: var Window, theme:Theme): string =
  this.ini.theme = theme
  utils.setTheme(theme)
  return $theme

#----------
# getTheme
#----------
proc getTheme*(this: Window): Theme =
  return this.ini.theme

#---------------
# getThemeLabel
#---------------
proc getThemeLabel*(this: Window): string =
  return $this.ini.theme
