# Compiling:
# nim c -d:ImGuiTextSelect thisFileName

import ../utils/[appImGui, infoWindow]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 800

const table = [
    "Line 1".cstring,
    "Line 2",
    "Line 3",
    "A longer line",
    "Text selection in Dear ImGui",
    "UTF-8 characters Ë ⑤ 三【 】┌──┐",
    "世界平和",
    nil
]

proc getNumLines(userdata: pointer) : csize_t {.cdecl.} =
  var clines = cast[cstringArray](userdata)
  var count:csize_t = 0;
  while not clines[count].isNil:
    inc count
  return count

proc getLineAtIdx(idx:csize_t, userdata: pointer, out_len: ptr csize_t): cstring {.cdecl.} =
  var clines = cast[cstringArray](userdata)
  if not out_len.isNil:
    out_len[] = clines[idx].len.csize_t
  return clines[idx]

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="Dear ImGui Window")
  defer: destroyImGui(win)


  var pTextselect = textselect_create(getLineAtIdx, getNumLines, addr table[0], 0 )
  let pio = igGetIO_Nil()

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    infoWindow(win)

    #---------------------------
    # Show ImGuiTextSelect demo
    #---------------------------
    block:
      igBegin("Nim: ImGuiTextSelect demo", nil, 0)

      igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / pio.Framerate, pio.Framerate)
      igSeparatorText("Runing with C API");

      igBeginChild_Str("text", ImVec2(x: 0, y: 0), 0, ImGuiWindowFlags_NoMove.cint);
      igPushFont(nil, 30) # Zoom font
      var num = getNumLines(addr table[0])
      for i in 0..<num:
        let line = getLineAtIdx(i, addr table[0], nil)
        igTextUnformatted(line, nil)
      textselect_update(pTextselect)
      igPopFont();
      if igBeginPopupContextWindow(nil, 1):
        igBeginDisabled(0 ==  textselect_has_selection(pTextselect))
        if igMenuItem_Bool("Copy", "Ctrl+C", false, true):
          textselect_copy(pTextselect)
        igEndDisabled()
        if igMenuItem_Bool("Select all", "Ctrl+A", false, true):
          textselect_select_all(pTextselect)
        if igMenuItem_Bool("Clear selection", nil, false, true):
          textselect_clear_selection(pTextselect)
        igEndPopup()
      igEndChild()
      igEnd()

    #--------
    # render
    #--------
    render(win)

  #### end while

#------
# main
#------
main()
