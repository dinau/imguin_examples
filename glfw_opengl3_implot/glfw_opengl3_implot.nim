# Compiling:
# nim c -d:ImPlotEnable glfw_opengl3_implot

import std/[random, sugar]
import ../utils/[appImGui, infoWindow]
import implotFuncs

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 800

#--------------
# imPlotWindow
#--------------
proc imPlotWindow(fshow:var bool) =
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
    igBegin("Plot Window", addr fshow, 0)
    defer: igEnd()
    block:
      ImPlotBeginPlot("My Plot",vec2(0.0f, 0.0f), 0.ImplotFlags)
      defer: ImPlotEndPlot()
      # See ./implotFuncs.nim
      ImPlotPlotBars("My Bar Plot",bar_data.ptz ,bar_data.len.cint)
      ImPlotPlotLine("My Line Plot", x_data.ptz ,y_data.ptz, xdata.len.cint)

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, implot = true)
  defer: destroyImGui(win)

  var
    showImPlotWindow = true

  # for ImPlot
  discard initRand()
  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    infoWindow(win)

    # ImPlot test
    if showImPlotWindow:
      ImplotShowDemoWindow(addr showImPlotWindow)
      imPlotWindow(showImPlotWindow)
    #
    render(win)
    if not showImPlotWindow:
      win.handle.setWindowShouldClose(true) # End program

  #### end while

#------
# main
#------
main()
