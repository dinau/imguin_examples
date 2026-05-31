# Compiling:
# nim c glfw_opengl3_base

import ../utils/[appImGui]

import licenseNotices

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

#----------
# gui_main
#----------
proc gui_main(win: var AppWindow) =
  var
    showLicensesWindow = true

  #-----------
  # main loop
  #-----------
  while not win.shouldClose:
    win.pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    infoWindow(win)

    if showLicensesWindow:
      licenseNotices(addr showLicensesWindow)

    #--------
    # render
    #--------
    render(win)
    if not showLicensesWindow:
      win.shouldClose = true # Exit program

  #### end while

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title = "License Window")
  defer: destroyImGui(win)

  discard setupFonts()

  win.setTheme(Classic)
  gui_main(win)

#------
# main
#------
main()
