import std/[os, strutils, parsecfg, parseutils, strformat]

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

import imguin/[glad/gl, cimgui, impl_sdl3, impl_sdlgpu3, simple]
export              gl, cimgui, impl_sdl3, impl_sdlgpu3, simple

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
  gpu_device: ptr SDL_GPUDevice
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
proc createImGui*(w,h: cint, imnodes:bool = false, implot:bool = false, title:string="ImGui window SDL3 renderer"): WindowSdl =
  if not SDL_Init(SDL_INIT_VIDEO or SDL_INIT_GAMEPAD):
    echo "\nError!: SDL_Init()"

  result.ini.viewportWidth = w
  result.ini.viewportHeight = h
  result.loadIni()

  const SDL_WINDOW_RESIZABLE = 0x0000000000000020'u64
  const SDL_WINDOW_OPENGL    = 0x0000000000000002'u64
  const SDL_WINDOW_HIDDEN    = 0x0000000000000008'u64
  const SDL_WINDOW_HIGH_PIXEL_DENSITY = 0x0000000000002000'u64
  var flags = SDL_WINDOW_RESIZABLE or SDL_WINDOW_HIDDEN or SDL_WINDOW_HIGH_PIXEL_DENSITY
  var window = SDL_CreateWindow(title
                               , result.ini.viewportWidth , result.ini.viewportHeight
                               , flags.SDL_WindowFlags)
  if isNil window:
    echo "Error!: SDL_CreateWindow()"
    quit 1

  # Create GPU Device
  const SDL_GPU_SHADERFORMAT_INVALID  =  0'u32
  const SDL_GPU_SHADERFORMAT_PRIVATE  = (1'u32 shl 0) #/**< Shaders for NDA'd platforms. */
  const SDL_GPU_SHADERFORMAT_SPIRV    = (1'u32 shl 1) #/**< SPIR-V shaders for Vulkan. */
  const SDL_GPU_SHADERFORMAT_DXBC     = (1'u32 shl 2) #/**< DXBC SM5_1 shaders for D3D12. */
  const SDL_GPU_SHADERFORMAT_DXIL     = (1'u32 shl 3) #/**< DXIL SM6_0 shaders for D3D12. */
  const SDL_GPU_SHADERFORMAT_MSL      = (1'u32 shl 4) #/**< MSL shaders for Metal. */
  const SDL_GPU_SHADERFORMAT_METALLIB = (1'u32 shl 5) #/**< Precompiled metallib shaders for Metal. */
  const flags_gpu = SDL_GPU_SHADERFORMAT_SPIRV +  SDL_GPU_SHADERFORMAT_DXIL + SDL_GPU_SHADERFORMAT_METALLIB
  result.gpu_device = SDL_CreateGPUDevice(flags_gpu.SDL_GPUShaderFormat, true , nil)
  if result.gpu_device.isNil:
    echo(fmt"Error: SDL_CreateGPUDevice(): {SDL_GetError()}\n")
    quit -1

  # Claim window for GPU Device
  if not SDL_ClaimWindowForGPUDevice(result.gpu_device, window):
    echo(fmt"Error: SDL_ClaimWindowForGPUDevice(): {SDL_GetError()}\n")
    quit -1
  #SDL_SetGPUSwapchainParameters(result.gpu_device, window, SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL_GPU_PRESENTMODE_MAILBOX)
  SDL_SetGPUSwapchainParameters(result.gpu_device, window, SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL_GPU_PRESENTMODE_VSYNC)

  result.renderer = SDL_CreateRenderer(window, nil) # TODO for Image load ?
  #SDL_SetRenderVSync(result.renderer, 1);
  #if isNil result.renderer:
  #  quit -1

  SDL_SetWindowPosition(window, result.ini.startupPosX, result.ini.startupPosY)

  # Setup ImGui
  igCreateContext(nil)
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

  # Setup Platform/Renderer backends
  ImGui_ImplSDL3_InitForSDLGPU(window)
  var init_info: ImGui_ImplSDLGPU3_InitInfo  #//= {};
  init_info.Device = result.gpu_device
  init_info.ColorTargetFormat = SDL_GetGPUSwapchainTextureFormat(result.gpu_device, window)
  init_info.MSAASamples = SDL_GPU_SAMPLECOUNT_1
  ImGui_ImplSDLGPU3_Init(addr init_info)

  if TransparentViewport:
    result.ini.clearColor = ccolor(elm:(x:0f, y:0f, z:0f, w:0.0f)) # Transparent
  result.handle = window

  setTheme(Classic)


  result.showWindowDelay = 2 # TODO

#--------
# render
#--------
proc render*(win: var WindowSdl) =
    igRender()
    var draw_data = igGetDrawData()
    var is_minimized = (draw_data.DisplaySize.x <= 0.0 and draw_data.DisplaySize.y <= 0.0)

    var command_buffer = SDL_AcquireGPUCommandBuffer(win.gpu_device) # Acquire a GPU command buffer

    var swapchain_texture: ptr SDL_GPUTexture
    SDL_AcquireGPUSwapchainTexture(command_buffer, win.handle, addr swapchain_texture, nil, nil) # Acquire a swapchain texture

    if (swapchain_texture != nil) and (not is_minimized):
      # This is mandatory: call Imgui_ImplSDLGPU3_PrepareDrawData() to upload the vertex/index buffer!
      Imgui_ImplSDLGPU3_PrepareDrawData(draw_data, command_buffer)

      #// Setup and start a render pass
      var target_info: SDL_GPUColorTargetInfo  # = {}
      target_info.texture = swapchain_texture
      target_info.clear_color.r =  win.ini.clearColor.elm.x
      target_info.clear_color.g =  win.ini.clearColor.elm.y
      target_info.clear_color.b =  win.ini.clearColor.elm.z
      target_info.clear_color.a =  win.ini.clearColor.elm.w
      target_info.load_op = SDL_GPU_LOADOP_CLEAR
      target_info.store_op = SDL_GPU_STOREOP_STORE
      target_info.mip_level = 0
      target_info.layer_or_depth_plane = 0
      target_info.cycle = false
      target_info.resolve_texture = nil
      target_info.resolve_mip_level = 0
      target_info.resolve_layer = 0
      target_info.cycle_resolve_texture = false
      target_info.padding1 = 0
      target_info.padding2 = 0
      var render_pass = SDL_BeginGPURenderPass(command_buffer, addr target_info, 1, nil)

      # Render ImGui
      ImGui_ImplSDLGPU3_RenderDrawData(draw_data, command_buffer, render_pass, nil)

      SDL_EndGPURenderPass(render_pass)
    ## end if
    #---------------------------
    # Submit the command buffer
    #---------------------------
    SDL_SubmitGPUCommandBuffer(command_buffer)

    #
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
  SDL_WaitForGPUIdle(win.gpu_device)
  ImGui_ImplSDL3_Shutdown()
  ImGui_ImplSDLGPU3_Shutdown()
  when defined(ImPlotEnable):
    if win.implot:
      win.imPlotContext.ImPlotDestroyContext()
  when defined(ImNodesEnable):
    if win.imnodes:
      imnodes_DestroyContext(nil)
  igDestroyContext(nil)

  SDL_ReleaseWindowFromGPUDevice(win.gpu_device, win.handle)
  SDL_DestroyGPUDevice(win.gpu_device);
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
  ImGui_ImplSDLGPU3_NewFrame()
  ImGui_ImplSDL3_NewFrame()
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
