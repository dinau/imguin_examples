# Compiling:
# nim c glfw_opengl3_iconfont_viewer
import std/[pegs,strformat]

import ../utils/[appImGui, infoWindow]
import ./iconFontsTblDef
import ./iconFontsTbl2Def

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="Icon font viewer demo")
  defer: destroyImGui(win)
  setTheme(Dark)
  var
    showIconFontViewWindow = true
    sBuf = newString(200)

  var listBoxTextureID: GLuint # Must be == 0 at first
  defer: glDeleteTextures(1, addr listBoxTextureID)

  var pio = igGetIO()
  var item_current = 0.cint
  var wsZoom:cfloat = 45

  let green = vec4(0.0, 1.0, 0.0, 1.0)

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    infoWindow(win)

    if showIconFontViewWindow:
      igBegin("Icon Font Viewer", addr showIconFontViewWindow, 0)
      defer: igEnd()
      igSeparatorText(cstring(ICON_FA_FONT_AWESOME & " Icon font view: " & $iconFontsTbl.len & " icons"))
      #
      const listBoxWidth = 320.int             # The value must be 2^n
      block:
        igText("No.[%4d]", item_current);     igSameLine()
        sBuf = $iconFontsTbl[item_current]
        if igButton(ICON_FA_COPY & " Copy to", vec2(0, 0)):
          if sBuf =~ peg"@' '{'ICON'.+}":
            igSetClipboardText(matches[0].cstring)
        setTooltip("Clipboard") # Show tooltip help

      # Show ListBox header
      igSetNextItemWidth(listBoxWidth.float)
      igInputText("##".cstring, sBuf.cstring, sBuf.len.csize_t, ImGui_TextFlags_None.cint,nil,nil)

      #-----------------------
      # Show icons in ListBox
      #-----------------------
      block:
        var
          listBoxPosTop:ImVec2
          listBoxPosEnd:ImVec2
        igNewline()
        igGetCursorScreenPos(addr listBoxPosTop) # Get absolute pos.
        igSetNextItemWidth(listBoxWidth.float)
        igListBox_Str_arr("##".cstring
                          , addr item_current
                          , cast[ptr UncheckedArray[cstring]](addr iconFontsTbl[0])
                          , iconFontsTbl.len.cint, 34)
        igGetCursorScreenPos(addr listBoxPosEnd) # Get absolute pos.

        # Show magnifying glass (Zoom in Toolchip)
        if igIsItemHovered(ImGui_HoveredFlags_DelayNone.cint):
          if (pio.MousePos.x - listBoxPosTop.x ) < 50:
            zoomGlass(listBoxTextureID, listBoxWidth, listBoxPosTop, listBoxPosEnd, capture=true )

    #---------------------
    # Show icons in Table
    #---------------------
    block:
      igBegin("Icon Font Viewer2", nil, 0)
      defer: igEnd()

      igText("%s", " Zoom x"); igSameLine()
      igSliderFloat("##Zoom1", addr wsZoom, 30, 90, "%.1f", 0)
      igSeparator()

      igBeginChild("child2")
      defer: igEndChild()

      var flags{.global.} = ImGuiTableFlags_RowBg.cint or ImGuiTableFlags_BordersOuter.cint or ImGuiTableFlags_BordersV.cint or ImGuiTableFlags_Resizable.cint or ImGuiTableFlags_Reorderable.cint or ImGuiTableFlags_Hideable.cint
      let TEXT_BASE_HEIGHT = igGetTextLineHeightWithSpacing()
      let outer_size = vec2(0.0f, TEXT_BASE_HEIGHT * 8)
      const COL = 10
      if igBeginTable("table_scrolly", COL, flags, outer_size, 0):
        defer: igEndTable()
        for row in 0..<(iconFontsTbl2.len div COL):
          igTableNextRow(0, 0.0)
          for column in 0 ..< COL:
            let ix = (row * COL + column).cint
            igTableSetColumnIndex(column.cint)
            #igSetWindowFontScale(wsZoom)
            igPushFont(nil, wsZoom)
            # Select 1: text
            igText("%s", iconFontsTbl2[ix][0])
            # Select 2: Button
            #if igButton(iconFontsTbl2[ix][0], vec2(0,0)):
            #  discard
            if igIsItemHovered(0):
               #item_highlighted_idx = ix
               item_current = ix
            igPopFont()
            let iconFontLabel = iconFontsTbl2[ix][1]
            setTooltip(iconfontLabel, color=green)
            #igSetWindowFontScale(wsNormal)
            block:
              igPushID_int(ix)
              defer: igPopID()
              if igBeginPopupContextItem("Contex Menu", 1):
                defer: igEndPopup()
                if igMenuItem_bool("Copy to clip board", shortcut=nil, selected=false, enabled=true):
                  echo fmt"{iconFontsTbl2[ix][1]}"
                  item_current = ix
                  igSetClipboardText(iconFontsTbl2[ix][1].cstring)

    #----------------------
    #-- Text filter window
    #----------------------
    block:
      igBegin("Icon Font filter", nil, 0)
      defer:igEnd()
      var seqFilter{.global.}:seq[string]
      igText("(Copy)")
      if igIsItemHovered(ImGui_HoveredFlags_DelayNone.cint):
        if seqFilter[0] =~ peg("@{ICON.+}"):
          igSetClipboardText(matches[0].cstring)
      seqFilter = @[]
      setTooltip("Copied first line to clipboard !", color=green) # Show tooltip help
      igSameLine()
      var filter = ImGuiTextFilter_ImGuiTextFilter("")
      ImGuiTextFilter_Draw(filter, "Filter", 0)
      for i, str in iconFontsTbl:
        if ImGuiTextFilter_PassFilter(filter, str, nil):
          igText("[%04d]  %s", i, str)
          seqFilter.add $str

    #------------
    render(win)
    if not showIconFontViewWindow:
      win.handle.setWindowShouldClose(true) # End program

    #### end while

#------
# main
#------
main()
