# Compiling:
# nim c glfw_opengl3_iconfont_viewer
import std/[pegs,strformat]

import ../utils/appImGui
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
  setTheme(dark)
  var
    showDemoWindow = true
    showIconFontViewWindow = true
    showFirstWindow = true
    sBuf = newString(200)

  var listBoxTextureID: GLuint # Must be == 0 at first
  defer: glDeleteTextures(1, addr listBoxTextureID)

  var pio = igGetIO()
  var item_current{.global.} = 0.cint

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    if showDemoWindow:
      igShowDemoWindow(addr showDemoWindow)

    # show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Nim: Dear ImGui test with Futhark", addr showFirstWindow, 0)
      defer: igEnd()
      #
      igText((ICON_FA_COMMENT & " " & getFrontendVersionString()).cstring)
      igText((ICON_FA_COMMENT_SMS & " " & getBackendVersionString()).cstring)
      igText("%s %s", ICON_FA_COMMENT_DOTS & " Dear ImGui", igGetVersion())
      igText("%s%s", ICON_FA_COMMENT_MEDICAL & " Nim-", NimVersion)
      igText("Application average %.3f ms/frame (%.1f FPS)".cstring, (1000.0f / igGetIO().Framerate).cfloat, igGetIO().Framerate.cfloat)

    if showIconFontViewWindow:
      igBegin("Icon Font Viewer", addr showIconFontViewWindow, 0)
      defer: igEnd()
      igSeparatorText(cstring(ICON_FA_FONT_AWESOME & " Icon font view: " & $iconFontsTbl.len & " icons"))
      #
      const listBoxWidth = 320.int             # The value must be 2^n
      block:
        igText("No.[%4d]", item_current);     igSameLine(0,-1.0)
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
      const wsZoom = 2.5
      const wsNormal = 1.0
      defer: igEnd()
      var flags{.global.} = ImGuiTableFlags_RowBg.cint or ImGuiTableFlags_BordersOuter.cint or ImGuiTableFlags_BordersV.cint or ImGuiTableFlags_Resizable.cint or ImGuiTableFlags_Reorderable.cint or ImGuiTableFlags_Hideable.cint
      let TEXT_BASE_HEIGHT = igGetTextLineHeightWithSpacing()
      let outer_size = vec2(0.0f, TEXT_BASE_HEIGHT * 8)
      const COL = 10
      if igBeginTable("table_scrolly", COL, flags, outer_size, 0):
        defer: igEndTable()
        for row in 0..<(1390 div COL):
          igTableNextRow(0, 0.0)
          for column in 0 ..< COL:
            let ix = (row * COL + column).cint
            igTableSetColumnIndex(column.cint)
            igSetWindowFontScale(wsZoom)
            igText("%s", iconFontsTbl2[ix][0])
            let iconFontLabel = iconFontsTbl2[ix][1]
            setTooltip(iconfontLabel, color=vec4(0.0, 1.0, 0.0, 1.0))
            igSetWindowFontScale(wsNormal)
            block:
              igPushID_int(ix)
              defer: igPopID()
              if igBeginPopupContextItem("Contex Menu", 1):
                defer: igEndPopup()
                if igMenuItem_bool("Copy to clip board", shortcut=nil, selected=false, enabled=true):
                  echo fmt"{iconFontsTbl2[ix][1]}"
                  item_current = ix
                  igSetClipboardText(iconFontsTbl2[ix][1].cstring)

    #
    render(win)
    if not showFirstWindow and not showDemoWindow and not showIconFontViewWindow:
      win.handle.setWindowShouldClose(true) # End program

    #### end while

#------
# main
#------
main()
