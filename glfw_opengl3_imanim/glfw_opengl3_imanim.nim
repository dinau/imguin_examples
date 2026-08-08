# Work in progress

# Compiling for desktop application:
#   $ make app
#   or
#   $ nim c -d:strip glfw_opengl3_imanim.nim
#
# Compiling for Emscripten (WebAssembly):
#   $ make
#   or
#   $ make run
#
# See ./Makefile, ./config.nims

{.passC: "-I../../libs/cimanim/libs/ImAnim".}
{.compile: "../../libs/cimanim/cimanim.cpp".}
{.compile: "../../libs/cimanim/libs/ImAnim/im_anim.cpp".}
{.compile: "../../libs/cimanim/libs/ImAnim/im_anim_demo.cpp".}
{.compile: "../../libs/cimanim/libs/ImAnim/im_anim_doc.cpp".}
{.compile: "../../libs/cimanim/libs/ImAnim/im_anim_usecase.cpp".}

{.push importc, cdecl.}
proc cimanim_demoWindow*()
proc cimanim_docWindow*()
proc cimanim_usecaseWindow*()
proc cimanim_update_begin_frame()
proc cimanim_clip_update(tm: cfloat)
{.pop.}

import ../utils/[utils, setupFonts]
import ../licenses_window/licenseNotices
import ../utils/appImGuiWasm

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

var
  win: AppWindow
  pio: ptr ImGuiIO

#----------
# gui_main
#----------
proc gui_main() =
  var showLicenseNotices {.global.} = false
  pio = igGetIO_Nil()

  #---------------------------
  # Init imgui_zoomable_image
  #---------------------------

  #-----------
  # main loop
  #-----------
  emscriptenMainloopBegin(win):
    win.pollEvents()

    newFrame()

    # >>> ImAnim frame setup (required every frame) <<<
    cimanim_update_begin_frame()
    cimanim_clip_update(pio.DeltaTime)

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
      licenseNotices(addr showLicenseNotices)
      win.setTheme(Classic)

    # Show demo
    cimanim_demoWindow()
    cimanim_docWindow()
    cimanim_usecaseWindow()

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
