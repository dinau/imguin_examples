# Compiling:
# nim c -d:ImPlotEnable -d:ImPlot3DEnable glfw_opengl3_implot3d.nim

import std/[math, random, sugar]
import ../utils/appImGui
import implot3dFuncs

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 800

#--------------
# imPlotWindow
#--------------
proc imPlotWindow() =
  var
    bar_data{.global.}:seq[Ims32]
    x_data  {.global.}:seq[Ims32]
    y_data  {.global.}:seq[Ims32]
  once: # This needs when set up compilation option to --mm:arc,--mm:orc and use nim-2.0.0 later,
        # workaround {.global.} pragma issue.
    bar_data= collect(for i in 0..10: rand(100).Ims32)
    x_data  = collect(for i in 0..10: i.Ims32)
    y_data  = collect(for i in 0..10: (i * i).Ims32)

  block:
    igBegin("Plot Window", nil, 0)
    defer: igEnd()
    block:
      ImPlotBeginPlot("My Plot",vec2(0.0f, 0.0f), 0.ImplotFlags)
      defer: ImPlotEndPlot()
      # See ./implotFuncs.nim
      ImPlotPlotBars("My Bar Plot",bar_data.ptz ,bar_data.len.cint)
      ImPlotPlotLine("My Line Plot", x_data.ptz ,y_data.ptz, xdata.len.cint)

#--------------
# imPlot3dWindow
#--------------
proc imPlot3dWindow() =
  var
    xs1{.global.}:array[1001,cfloat]
    ys1{.global.}:array[1001,cfloat]
    zs1{.global.}:array[1001,cfloat]
    xs2{.global.}:array[20,cdouble]
    ys2{.global.}:array[20,cdouble]
    zs2{.global.}:array[20,cdouble]

  for i in 0..<1001:
    xs1[i] =  i.cfloat * 0.001
    ys1[i] =  0.5 + 0.5 * cos(50 * (xs1[i] + igGetTime() / 10))
    zs1[i] =  0.5 + 0.5 * sin(50 * (xs1[i] + igGetTime() / 10))
  for i in 0..<20:
    xs2[i] = i.cfloat * 1 / 19.0.cfloat;
    ys2[i] = xs2[i] * xs2[i];
    zs2[i] = xs2[i] * ys2[i];

  block:
    igBegin("Plot3D Window", nil, 0)
    defer: igEnd()
    block:
      ImPlot3dBeginPlot("Line Plots",vec2(0.0f, 0.0f), 0.cint)
      defer: ImPlot3DEndPlot()
      # See ./implotFuncs.nim
      let IMPLOT3D_AUTO_COL = vec4(0, 0, 0, -1) # Deduce color automatically
      let IMPLOT3D_AUTO     = -1.0.cfloat       # Deduce variable automatically
      imPlot3dSetupAxes("x", "y", "z")
      imPlot3dPlotline("f(x)", xs1.ptz,  ys1.ptz,  zs1.ptz, 1001)
      imPlot3dSetNextMarkerStyle(Circle)
      imPlot3dPlotLine("g(x)", xs2.ptz, ys2.ptz, zs2.ptz, 20, Segments)

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, implot3d = true)
  defer: destroyImGui(win)

  # for ImPlot
  discard initRand()

  var fShow = true
  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    igShowDemoWindow      (nil)
    ImplotShowDemoWindow  (nil)
    Implot3dShowDemoWindow(nil)

    # ImPlot test
    imPlotWindow()
    imPlot3dWindow()
    #
    render(win)

    #if not showDemoWindow and not showImPlotWindow:
    #  win.handle.setWindowShouldClose(true) # End program

  #### end while

#------
# main
#------
main()
