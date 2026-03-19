# Compiling:
# nim c -d:SDL sdl3_vulkan

# SDL3 settings
when defined(windows):
  const sdlPath = "../libs/SDL3/x86_64-w64-mingw32"
  {.passC: "-I" & sdlPath & "/include".}
  {.passC: "-I" & sdlPath & "/include/SDL3".}
  {.passL: "-L" & sdlPath & "/lib".}
when defined(linux): # for linux Debian 11 Bullseye or later
  {.passC: "-I/usr/include/SDL3".}

import std/[os, strutils, math, strformat]
import sdl3_nim
import imguin/[cimgui, impl_sdl3, impl_vulkan, simple]
import ../utils/[utils, setupFonts, vecs, togglebutton]

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const DebugEcho = true
proc debugEcho(str: string) =
  if DebugEcho:
    echo str

const MainWinWidth = 1024
const MainWinHeight = 900

# Present mode selection: VK_PRESENT_MODE_FIFO_KHR (V-Sync enabled)
const APP_USE_UNLIMITED_FRAME_RATE = false

# ============================================================
# Global Variables
# ============================================================
var
  g_Allocator {.exportc: "g_Allocator", global.}: ptr VkAllocationCallbacks
  g_Instance {.exportc: "g_Instance", global.}: vulkan.VkInstance
  g_PhysicalDevice: vulkan.VkPhysicalDevice
  g_Device: VkDevice
  g_QueueFamily: uint32 = uint32.high
  g_Queue: VkQueue
  g_PipelineCache: VkPipelineCache
  g_DescriptorPool: VkDescriptorPool
  g_MainWindowData: ImGui_ImplVulkanH_Window
  g_MinImageCount: uint32 = 2
  g_SwapChainRebuild: bool = false

# Some procs
proc getFrontendVersionString*(): string =
  var sVer = $SDL_GetRevision()
  #sVer = sVer.split("-")[2]
  return fmt"SDL {sVer}"

# Version helper
template vkVersionMajor(v: uint32): uint32 = v shr 22
template vkVersionMinor(v: uint32): uint32 = (v shr 12) and 0x3ff
template vkVersionPatch(v: uint32): uint32 = v and 0xfff

proc versionToString(v: uint32): string =
  fmt"{vkVersionMajor(v)}.{vkVersionMinor(v)}.{vkVersionPatch(v)}"

proc getBackendVersionString*(): string =
  # Get Vulkan API version
  var apiVersion: uint32
  discard vkEnumerateInstanceVersion(addr apiVersion)
  return versionToString(apiVersion)

proc getVulkanGPUVersionString*(): string =
  # Get Vulkan API version
  var props: VkPhysicalDeviceProperties
  vkGetPhysicalDeviceProperties(g_PhysicalDevice, addr props)
  let gpuName = cast[cstring](addr props.deviceName[0])
  let apiVer = props.apiVersion
  let ret = fmt"{gpuName} : [v{versionToString(apiVer)}]"
  return ret

# ============================================================
# Helper: Vulkan Error Check
# ============================================================
proc checkVkResult(err: VkResult) {.cdecl.} =
  ## If VkResult is not success, output to stderr. Abort if the value is negative.
  if err == Success: # VK_SUCCESS
    return
  stderr.writeLine(fmt"[vulkan] Error: VkResult = {err}")
  if err < Success:
    quit(1)

# ============================================================
# Extension Availability Check
# ============================================================
proc isExtensionAvailable(properties: seq[VkExtensionProperties], extension: cstring): bool =
  ## Check if `extension` is included in the list of available extensions
  for p in properties:
    if cast[cstring](addr p.extensionName[0]) == extension:
      return true
  return false

# ============================================================
# Vulkan Setup
# ============================================================
proc setupVulkan(instance_extensions: var seq[string]) =
  debugEcho "[vulkan] Start setupVulkan()"
  ## Create Vulkan instance, physical device, logical device, and descriptor pool

  # --- Create Vulkan Instance ---
  debugEcho "[vulkan] Creating Vulkan instance..."
  # Construct VkInstanceCreateInfo and enable extensions
  # Add VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2 if available
  var createInfo: VkInstanceCreateInfo
  createInfo.sType = StructureTypeInstanceCreateInfo

  # Enumerate available instance extensions
  # Idiomatic pattern: call vkEnumerateInstanceExtensionProperties twice
  # 1st: Get count | 2nd: Get data
  var propertiesCount: uint32
  var err1 = vkEnumerateInstanceExtensionProperties(nil, addr propertiesCount, nil)
  checkVkResult(err1)
  var availableProps = newSeq[VkExtensionProperties](propertiesCount.int)
  debugEcho fmt"[vulkan] propertiesCount: {propertiesCount}"
  var err2 = vkEnumerateInstanceExtensionProperties(nil, addr propertiesCount, addr availableProps[0])
  checkVkResult(err2)
  for n, prop in availableProps:
    debugEcho fmt"  [{n:>2}]: [{$cast[cstring](addr prop.extensionName[0])}]"

  # Add optional extensions to the ones provided by SDL
  if isExtensionAvailable(availableProps, VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME):
    debugEcho "[vulkan] true == isExtensionAvailable()"
    instance_extensions.add(VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME)

  createInfo.enabledExtensionCount = instance_extensions.len.uint32
  createInfo.ppEnabledExtensionNames = instance_extensions.allocCStringArray
  checkVkResult(vkCreateInstance(createInfo.addr, g_Allocator, g_Instance.addr))
  deallocCStringArray(createInfo.ppEnabledExtensionNames)

  # --- Select Physical Device (GPU) ---
  g_PhysicalDevice = ImGui_ImplVulkanH_SelectPhysicalDevice(g_Instance)
  assert cast[int64](g_PhysicalDevice) != 0
  debugEcho "[vulkan] Selecting physical device..."

  # --- Select Graphics Queue Family ---
  g_QueueFamily = ImGui_ImplVulkanH_SelectQueueFamilyIndex(g_PhysicalDevice)
  assert g_QueueFamily != (-1).uint32
  debugEcho "[vulkan] Selecting queue family..."

  # --- Create Logical Device (with 1 queue) ---
  var deviceExtensions: seq[string] = @["VK_KHR_swapchain"]
  let queuePriority = [1.0f]
  var queueInfo: VkDeviceQueueCreateInfo
  queueInfo.sType = StructureTypeDeviceQueueCreateInfo
  queueInfo.queueFamilyIndex = g_QueueFamily
  queueInfo.queueCount = 1
  queueInfo.pQueuePriorities = addr queuePriority[0]

  var deviceCreateInfo: VkDeviceCreateInfo
  deviceCreateInfo.sType = StructureTypeDeviceCreateInfo
  deviceCreateInfo.queueCreateInfoCount = 1
  deviceCreateInfo.pQueueCreateInfos = addr queueInfo
  deviceCreateInfo.enabledExtensionCount = deviceExtensions.len.uint32
  deviceCreateInfo.ppEnabledExtensionNames = deviceExtensions.allocCStringArray
  checkVkResult(vkCreateDevice(g_PhysicalDevice, addr deviceCreateInfo, g_Allocator, addr g_Device))
  deallocCStringArray(deviceCreateInfo.ppEnabledExtensionNames)
  vkGetDeviceQueue(g_Device, g_QueueFamily, 0, addr g_Queue)

  debugEcho "[vulkan] Logical device created."

  # --- Create Descriptor Pool ---
  # Adjust poolSizes and maxSets if you wish to load additional textures
  const IMGUI_IMPL_VULKAN_MINIMUM_IMAGE_SAMPLER_POOL_SIZE = 8 # Minimum per atlas
  var poolSizes = [
    VkDescriptorPoolSize(
      `type`: Descriptor_type_combined_image_sampler,
      descriptorCount: IMGUI_IMPL_VULKAN_MINIMUM_IMAGE_SAMPLER_POOL_SIZE
    )
  ]
  var poolInfo: VkDescriptorPoolCreateInfo
  poolInfo.sType = STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO
  poolInfo.flags = cast[VkDescriptorPoolCreateFlags](DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT)
  poolInfo.maxSets = poolSizes[0].descriptorCount
  poolInfo.poolSizeCount = poolSizes.len.uint32
  poolInfo.pPoolSizes = addr poolSizes[0]
  checkVkResult vkCreateDescriptorPool(g_Device, addr poolInfo, g_Allocator, addr g_DescriptorPool)

  debugEcho "[vulkan] Descriptor pool created."
  debugEcho "[vulkan] End setupVulkan()"

# ============================================================
# Vulkan Window Setup
# ============================================================
proc setupVulkanWindow(wd: ptr ImGui_ImplVulkanH_Window, surface: vulkan.VkSurfaceKHR, width, height: cint) =
  ## Create Swapchain, RenderPass, Framebuffers, etc.
  # Check for WSI support
  var res: VkBool32
  discard vkGetPhysicalDeviceSurfaceSupportKHR(g_PhysicalDevice, g_QueueFamily, surface, addr res)
  if res.uint32 != VK_TRUE:
    stderr.writeLine("Error no WSI support on physical device 0")
    quit(-1)

  # Select Surface Format
  # Priority: B8G8R8A8_UNORM, R8G8B8A8_UNORM, B8G8R8_UNORM, R8G8B8_UNORM
  # Color Space: VK_COLORSPACE_SRGB_NONLINEAR_KHR
  var requestSurfaceImageFormat = [FORMAT_B8G8R8A8_UNORM, FORMAT_R8G8B8A8_UNORM, FORMAT_B8G8R8_UNORM, FORMAT_R8G8B8_UNORM]
  const requestSurfaceColorSpace: VkColorSpaceKHR = COLORSPACE_SRGB_NONLINEAR_KHR
  wd.Surface = surface
  wd.SurfaceFormat = ImGui_ImplVulkanH_SelectSurfaceFormat(g_PhysicalDevice
    , wd.Surface
    , addr requestSurfaceImageFormat[0]
    , requestSurfaceImageFormat.len.cint
    , requestSurfaceColorSpace)
  # Select Present Mode: VK_PRESENT_MODE_FIFO_KHR (V-Sync)
  when APP_USE_UNLIMITED_FRAME_RATE:
    var present_modes = [PRESENT_MODE_MAILBOX_KHR, PRESENT_MODE_IMMEDIATE_KHR, PRESENT_MODE_FIFO_KHR]
  else:
    var present_modes = [PRESENT_MODE_FIFO_KHR] # array of VkPresentModeKHR
  wd.PresentMode = ImGui_ImplVulkanH_SelectPresentMode(g_PhysicalDevice, wd.Surface, addr present_modes[0], present_modes.len.cint)
  debugEcho fmt"[vulkan] Selected PresentMode: [{wd.PresentMode}]"

  # Create Swapchain, RenderPass, and Framebuffer
  ImGui_ImplVulkanH_CreateOrResizeWindow(g_Instance, g_PhysicalDevice, g_Device, wd,
                                          g_QueueFamily, g_Allocator, width, height, g_MinImageCount, 0.VkImageUsageFlags)
  debugEcho fmt"[vulkan] Window surface set up ({width}x{height})."

# ============================================================
# Vulkan Cleanup
# ============================================================
proc cleanupVulkan() =
  ## Destroy Descriptor Pool, Logical Device, and Instance
  vkDestroyDescriptorPool(g_Device, g_DescriptorPool, g_Allocator)
  vkDestroyDevice(g_Device, g_Allocator)
  vkDestroyInstance(g_Instance, g_Allocator)
  debugEcho "[vulkan] Vulkan resources destroyed."

proc cleanupVulkanWindow(wd: ptr ImGui_ImplVulkanH_Window) =
  ## Destroy Window Resources (Framebuffers, etc.) and Surface
  ImGui_ImplVulkanH_DestroyWindow(g_Instance, g_Device, wd, g_Allocator)
  vkDestroySurfaceKHR(g_Instance, wd.Surface, g_Allocator)
  debugEcho "[vulkan] Vulkan window destroyed."


# ============================================================
# Frame Rendering
# ============================================================
proc frameRender(wd: ptr ImGui_ImplVulkanH_Window; drawData: ptr ImDrawData) =
  ## Record ImGui draw data into Vulkan command buffer and submit to queue
  let dataPtrFrameSemaphoes = cast[ptr UncheckedArray[ImGui_ImplVulkanH_FrameSemaphores]](wd.FrameSemaphores.Data)
  let imageAcquiredSemaphore = dataPtrFrameSemaphoes[wd.SemaphoreIndex].ImageAcquiredSemaphore
  let renderCompleteSemaphore = dataPtrFrameSemaphoes[wd.SemaphoreIndex].RenderCompleteSemaphore
  var err = vkAcquireNextImageKHR(g_Device, wd.Swapchain, uint64.high, imageAcquiredSemaphore, 0.VkFence, addr wd.FrameIndex)
  if err == ERROR_OUT_OF_DATE_KHR or err == SUBOPTIMAL_KHR:
    g_SwapChainRebuild = true
  if err == ERROR_OUT_OF_DATE_KHR:
    return
  if err != SUBOPTIMAL_KHR:
    checkVkResult(err)

  let dataPtrFrames = cast[ptr UncheckedArray[ImGui_ImplVulkanH_Frame]](wd.Frames.Data)
  let fd = addr dataPtrFrames[wd.FrameIndex]

  # Fence Wait & Reset
  block:
    checkVkResult(vkWaitForFences(g_Device, 1, addr fd.Fence, VK_TRUE.VkBool32, uint64.high))
    checkVkResult(vkResetFences(g_Device, 1, addr fd.Fence))

  # Reset Command Pool & Begin Command Buffer
  block:
    checkVkResult(vkResetCommandPool(g_Device, fd.CommandPool, 0.VkCommandPoolResetFlags))
    var beginInfo: VkCommandBufferBeginInfo
    beginInfo.sType = STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO
    beginInfo.flags = (beginInfo.flags.uint32 or COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT.uint32).VkCommandBufferUsageFlags
    checkVkResult(vkBeginCommandBuffer(fd.CommandBuffer, addr beginInfo))

  # Start Render Pass
  block:
    var rpInfo: VkRenderPassBeginInfo
    zeroMem(addr rpInfo, sizeof(rpInfo))
    rpInfo.sType = STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO
    rpInfo.renderPass = wd.RenderPass
    rpInfo.framebuffer = fd.Framebuffer
    rpInfo.renderArea.extent.width = wd.Width.uint32
    rpInfo.renderArea.extent.height = wd.Height.uint32
    rpInfo.clearValueCount = 1
    rpInfo.pClearValues = addr wd.ClearValue
    vkCmdBeginRenderPass(fd.CommandBuffer, addr rpInfo, SUBPASS_CONTENTS_INLINE)

  # Record ImGui primitives into command buffer
  ImGui_ImplVulkan_RenderDrawData(cast[ptr ImDrawData](drawData), fd.CommandBuffer, VK_NULL_HANDLE.VkPipeLine)
  vkCmdEndRenderPass(fd.CommandBuffer)

  block:
    # Submit Command Buffer
    let waitStage = PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT.VkPipeLineStageFlags
    var submitInfo: VkSubmitInfo
    submitInfo.sType = STRUCTURE_TYPE_SUBMIT_INFO
    submitInfo.waitSemaphoreCount = 1
    submitInfo.pWaitSemaphores = addr imageAcquiredSemaphore
    submitInfo.pWaitDstStageMask = addr waitStage
    submitInfo.commandBufferCount = 1
    submitInfo.pCommandBuffers = addr fd.CommandBuffer
    submitInfo.signalSemaphoreCount = 1
    submitInfo.pSignalSemaphores = addr renderCompleteSemaphore
    checkVkResult vkEndCommandBuffer(fd.CommandBuffer)
    checkVkResult vkQueueSubmit(g_Queue, 1, addr submitInfo, fd.Fence)

# ============================================================
# Frame Present
# ============================================================
proc framePresent(wd: ptr ImGui_ImplVulkanH_Window) =
  ## Present rendering results to swapchain
  if g_SwapChainRebuild:
    return
  let dataPtrFrameSemaphoes = cast[ptr UncheckedArray[ImGui_ImplVulkanH_FrameSemaphores]](wd.FrameSemaphores.Data)
  let renderCompleteSemaphore = dataPtrFrameSemaphoes[wd.SemaphoreIndex].RenderCompleteSemaphore
  var presentInfo: VkPresentInfoKHR
  presentInfo.sType = STRUCTURE_TYPE_PRESENT_INFO_KHR
  presentInfo.waitSemaphoreCount = 1
  presentInfo.pWaitSemaphores = addr renderCompleteSemaphore
  presentInfo.swapchainCount = 1
  presentInfo.pSwapchains = addr wd.Swapchain
  presentInfo.pImageIndices = addr wd.FrameIndex

  let err = vkQueuePresentKHR(g_Queue, addr presentInfo)
  if err == ERROR_OUT_OF_DATE_KHR or err == SUBOPTIMAL_KHR:
    g_SwapChainRebuild = true
  if err == ERROR_OUT_OF_DATE_KHR:
    return
  if err != SUBOPTIMAL_KHR:
    checkVkResult(err)
  wd.SemaphoreIndex = (wd.SemaphoreIndex + 1) mod wd.SemaphoreCount

{.emit: """
  #include "vulkan/vulkan_core.h"
  #include "SDL_vulkan.h"
""".}

var window {.exportc: "window", global.}: ptr SDL_Window
var mainSurface {.exportc: "mainSurface", global.}: vulkan.VkSurfaceKHR

#------
# main
#------
proc main() =
  # Initialize Window Data structure
  g_MainWindowData = ImGui_ImplVulkanH_Window_ImGui_ImplVulkanH_Window()[]

  # ---- SDL Initialization ----
  # If using SDL_MAIN_USE_CALLBACKS, this would be inside SDL_AppInit()
  if not SDL_Init(SDL_INIT_VIDEO or SDL_INIT_GAMEPAD):
    echo fmt"Error: SDL_Init(): {SDL_GetError()}"
    quit(1)

  # ---- Create Window with Vulkan graphics context ----
  let mainScale = SDL_GetDisplayContentScale(SDL_GetPrimaryDisplay())
  const windowflags = SDL_WINDOW_VULKAN or SDL_WINDOW_RESIZABLE or SDL_WINDOW_HIDDEN or SDL_WINDOW_HIGH_PIXEL_DENSITY
  let windowW = cint(1280.0f * mainScale)
  let windowH = cint(800.0f * mainScale)
  window = SDL_CreateWindow("Dear ImGui SDL3+Vulkan example", windowW, windowH, windowFlags.SDL_WindowFlags)
  if window == nil:
    echo fmt"Error: SDL_CreateWindow(): {SDL_GetError()}"
    quit(1)

  # Get Vulkan Instance Extensions from SDL
  var extensions: seq[string] = @[]
  var sdl_extensions_count: uint32 = 0
  let sdl_extensions = SDL_Vulkan_GetInstanceExtensions(addr sdl_extensions_count)
  if isNil sdl_extensions:
    echo fmt"Error: SDL_Vulkan_GetInstanceExtensions(): {SDL_GetError()}\n"
    quit(1)
  for n in 0..<sdl_extensions_count:
    let ext = cast[ptr UncheckedArray[cstring]](sdl_extensions)
    extensions.add $ext[n]
  setupVulkan(extensions)

  when DebugEcho:
    debugEcho fmt("[vulkan] Extensions:")
    for i, ext in extensions:
      debugEcho fmt("  n={i}: [{ext}]")

  # ---- Create Window Surface ---- TODO
  {.emit: """
    bool err = SDL_Vulkan_CreateSurface((SDL_Window*)window
                           , (VkInstance)g_Instance
                           , (VkAllocationCallbacks*)g_Allocator
                           , (VkSurfaceKHR*)&mainSurface);
    if (err == 0){
      printf("Error!:Failed to create Vulkan mainSurface!: SDL_Vulkan_CreateSurface()\n");
      return ;
    }else{
      printf("[vulkan] \"mainSurface\" created.\n");
    }
  """.}

  # ---- Create Framebuffers (Swapchain, etc.) ----
  var w, h: int32
  SDL_GetWindowSize(window, addr w, addr h);
  var wd = g_MainWindowData.addr
  setupVulkanWindow(wd, mainSurface, w, h)
  SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED.cint, SDL_WINDOWPOS_CENTERED.cint)

  # ---- Initialize Dear ImGui context ----
  igCreateContext(nil)
  let io = igGetIO_Nil()
  io.ConfigFlags = io.ConfigFlags or
                   ImGui_ConfigFlags_NavEnableKeyboard.cint or
                   ImGui_ConfigFlags_NavEnableGamepad.cint or
                   ImGui_ConfigFlags_DockingEnable.cint
  debugEcho "Dear ImGui context created."

  # ---- Setup Style ----
  igStyleColorsDark(nil)

  let style = igGetStyle()
  style.ImGuiStyle_ScaleAllSizes(mainScale)
  style.FontScaleDpi = mainScale
  io.ConfigDpiScaleFonts = true
  io.ConfigDpiScaleViewports = true

  # Tweak WindowRounding/WindowBg for Platform Windows if viewports are enabled
  if 0 != (io.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
    style.WindowRounding = 0.0f
    style.Colors[ImGuiCol_WindowBg.cint].w = 1.0f

  # ---- Initialize Platform/Renderer Backends ----
  ImGui_ImplSDL3_InitForVulkan(window)
  var init_info: ImGui_ImplVulkan_InitInfo
  zeroMem(addr init_info, sizeof(init_info)) # Important: Clear structure
  init_info.Instance = g_Instance
  init_info.PhysicalDevice = g_PhysicalDevice
  init_info.Device = g_Device
  init_info.QueueFamily = g_QueueFamily
  init_info.Queue = g_Queue
  init_info.PipelineCache = g_PipelineCache
  init_info.DescriptorPool = g_DescriptorPool
  init_info.MinImageCount = g_MinImageCount
  init_info.ImageCount = wd.ImageCount
  init_info.Allocator = g_Allocator
  init_info.PipelineInfoMain.RenderPass = wd.RenderPass
  init_info.PipelineInfoMain.Subpass = 0
  init_info.PipelineInfoMain.MSAASamples = SAMPLE_COUNT_1_BIT
  init_info.CheckVkResultFn = checkVkResult
  doAssert ImGui_ImplVulkan_Init(addr init_info)
  debugEcho "ImGui backends initialized."

  var
    showDemoWindow = true
    #clear_color = ImVec4(x: 0.45, y: 0.55, z: 0.60, w: 1.00)
    clearColor: ccolor
    sBuf = newString(200)
    sFnameSelected{.global.}: string
    counter = 0
    done = false
    fval = 0.5f
    sw: bool = false
    strSw = $Theme.Dark
    TransparentViewport = false
    showWindowDelay = 2

  if TransparentViewport:
    clearColor = ccolor(elm: (x: 0f, y: 0f, z: 0f, w: 0.0f)) # Transparent
  else:
    clearColor = ccolor(elm: (x: 0.25f, y: 0.65f, z: 0.85f, w: 1.0f))

  # Add multibytes font
  discard setupFonts()

  let pio = igGetIO()
  #-----------
  # Main loop
  #-----------
  while not done:
    var event: SDL_Event
    while SDL_pollevent(addr event):
      discard ImGui_ImplSDL3_processEvent(addr event)
      if event.type_field == SDL_EVENT_QUIT.uint32:
        done = true
      if event.type_field == SDL_EVENT_WINDOW_CLOSE_REQUESTED.uint32 and
          event.window.windowID == SDL_GetWindowID(window):
        done = true

    if 0 != (SDL_GetWindowFlags(window) and SDL_WINDOW_MINIMIZED):
      SDL_Delay(10)
      continue

    # Newframe: Resize swap chain if needed
    var fb_width, fb_height: cint
    SDL_GetWindowSize(window, addr fb_width, addr fb_height)
    if (fb_width > 0) and
       (fb_height > 0) and
       (
        (g_SwapChainRebuild) or
        (g_MainWindowData.Width != fb_width) or
        (g_MainWindowData.Height != fb_height)
      ):
      ImGui_ImplVulkan_SetMinImageCount(g_MinImageCount)
      ImGui_ImplVulkanH_CreateOrResizeWindow(g_Instance
        , g_PhysicalDevice
        , g_Device
        , wd
        , g_QueueFamily
        , g_Allocator
        , fb_width
        , fb_height
        , g_MinImageCount
        , 0.VkImageUsageFlags)
      g_MainWindowData.FrameIndex = 0
      g_SwapChainRebuild = false

    # Start the Dear ImGui frame
    ImGui_ImplVulkan_NewFrame()
    ImGui_ImplSDL3_NewFrame()
    igNewFrame()

    #------------------
    # Show ImGui demo
    #------------------
    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    #------------------
    # Show main window
    #------------------
    block:
      igBegin("Nim: Dear ImGui + SDL3 + Vulkan", nil, 0)
      defer: igEnd()
      if igToggleButton(strSw, sw):
        if sw:
          strSw = $Theme.Light
          setTheme(Light)
        else:
          strSw = $Theme.Dark
          setTheme(Dark)
      #
      var s = getFrontendVersionString()
      s = ICON_FA_COMMENT & " " & s
      igText(s.cstring)
      #
      s = "Vulkan Lib-" & getBackendVersionString()
      s = ICON_FA_CUBES & " " & s
      igText(s.cstring)
      #
      s = "Vulkan GPU: " & getVulkanGPUVersionString()
      s = ICON_FA_MICRO_CHIP & " " & s
      igText(s.cstring)
      #
      igText(ICON_FA_COMMENT_DOTS & " Dear ImGui-"); igSameLine(0, -1.0)
      igText(igGetVersion())
      igText(ICON_FA_COMMENT_MEDICAL & " Nim-"); igSameLine(0, 0)
      igText(NimVersion);

      igInputTextWithHint("InputText", "Input text here", sBuf)
      s = "Input result:" & sBuf
      igText(s.cstring)
      igCheckbox("Demo window", addr showDemoWindow); igSameLine()
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

    #-----------
    # Rendering
    #-----------
    igRender()
    var main_draw_data = igGetDrawData()
    let main_is_minimized = (main_draw_data.DisplaySize.x <= 0.0f) or (main_draw_data.DisplaySize.y <= 0.0f)

    # Update clear color
    wd.ClearValue.color.float32[0] = clearColor.elm.x * clearColor.elm.w
    wd.ClearValue.color.float32[1] = clearColor.elm.y * clearColor.elm.w
    wd.ClearValue.color.float32[2] = clearColor.elm.z * clearColor.elm.w
    wd.ClearValue.color.float32[3] = clearColor.elm.w

    if not main_is_minimized:
      frameRender(wd, main_draw_data)

    # Update and Render additional Platform Windows (Multi-viewports)
    if 0 != (io.ConfigFlags and ImGui_ConfigFlags_ViewportsEnable.cint):
      igUpdatePlatformWindows()
      igRenderPlatformWindowsDefault(nil, nil)

    # Present Main Platform Window
    if not main_is_minimized:
      framePresent(wd);

    if showWindowDelay > 0:
      dec showWindowDelay
    else:
      once: # Avoid flickering screen at startup.
        SDL_ShowWindow(window)
  ### end while

  # Cleanup
  let err = vkDeviceWaitIdle(g_Device)
  checkVkResult(err)
  ImGui_ImplVulkan_Shutdown()
  ImGui_ImplSDL3_Shutdown()
  igDestroyContext(nil)

  cleanupVulkanWindow(wd)
  cleanupVulkan()

  SDL_DestroyWindow(window)
  SDL_Quit_proc()

#------
# main
#------
main()
