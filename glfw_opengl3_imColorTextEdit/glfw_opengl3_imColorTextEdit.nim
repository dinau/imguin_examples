# Compiling:
# nim c -d:ImColorTextEdit glfw_opengl3_imColorTextEdit.nim

# Refer to :
#            https://github.com/sonoro1234/LuaJIT-ImGui/blob/docking_inter/examples/CTE_sample.lua
#            https://github.com/sonoro1234/LuaJIT-ImGui
#            https://github.com/BalazsJako/ColorTextEditorDemo/blob/master/main.cpp
#            https://github.com/BalazsJako/ColorTextEditorDemo
import std/[paths]
import ../utils/appImGui

when defined(windows):
  when not defined(vcc): # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

# This is a programing font. https://github.com/yuru7/NOTONOTO
const fontFullPath = "./fonts/notonoto_v0.0.3/NOTONOTO-Regular.ttf"
const fileName = "main.cpp"

#----------
# gui_main
#----------
proc gui_main(win: var AppWindow) =
  var strText = readFile(fileName)
  let editor = TextEditor_TextEditor()
  TextEditor_SetLanguage(editor, Language_Cpp())
  TextEditor_SetText(editor, strText.cstring)

  TextEditor_SetPalette(editor, TextEditor_GetLightPalette())

  #var mLine: cint
  #var mColumn: cint
  var curPos: CursorPosition_c
  var fQuit = false

  let pio = igGetIO()

  # Setup programing fonts
  const textPoint = 14.5
  let textFont = pio.Fonts.ImFontAtlas_AddFontFromFileTTF(fontFullPath.cstring, textPoint.point2px, nil, nil);

  #-----------
  # main loop
  #-----------
  while not win.shouldClose:
    win.pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    win.infoWindow()

    curPos = TextEditor_GetCurrentCursorPosition(editor)
    block:
      let (_, fontName) = fontFullPath.Path.splitPath
      igBegin(("Text Editor Demo: Font: " & $fontName).cstring, nil, (ImGuiWindowFlags_HorizontalScrollbar.cuint or ImGuiWindowFlags_MenuBar.cuint).ImGuiWindowFlags)
      defer: igEnd()
      igSetWindowSize_Vec2(vec2(800, 600), ImGuiCond_FirstUseEver.ImGuiCond)
      #
      if igBeginMenuBar():
        defer: igEndMenuBar()
        if igBeginMenu("File", true):
          defer: igEndMenu()
          if igMenuItem("Save", "Ctrl-S", nil, true):
            strText = $TextEditor_GetText(editor)
            writeFile("main.cpp", strText)
            echo "saved"
          if igMenuItem("Quit", "Alt-F4"):
            fQuit = true
            echo("quit")

        if igBeginMenu("Edit", true):
          defer: igEndMenu()
          var ro = TextEditor_IsReadOnlyEnabled(editor)
          if igMenuItem("Read-only mode", nil, addr ro):
            TextEditor_SetReadOnlyEnabled(editor, ro)
          igSeparator()
          #
          if igMenuItem("Undo", "ALT-Backspace", nil, not ro and TextEditor_CanUndo(editor)):
            TextEditor_Undo(editor)
          if igMenuItem("Redo", "Ctrl-Y", nil, not ro and TextEditor_CanRedo(editor)):
            TextEditor_Redo(editor)
          igSeparator()
          #
          if igMenuItem("Copy", "Ctrl-C", nil, TextEditor_AnyCursorHasSelection(editor)):
            TextEditor_Copy(editor)
          if igMenuItem("Cut", "Ctrl-X", nil, not ro and TextEditor_AnyCursorHasSelection(editor)):
            TextEditor_Cut(editor)
          if igMenuItem("Paste", "Ctrl-V", nil, not ro and igGetClipboardText() != nil):
            TextEditor_Paste(editor)
          igSeparator();
          if igMenuItem("Select all", "Ctrl-A", nil, true):
            TextEditor_SelectAll(editor)
        #

        if igBeginMenu("Theme", true):
          defer: igEndMenu()
          if igMenuItem("Dark palette"):
            TextEditor_SetPalette(editor, TextEditor_GetDarkPalette())
          if igMenuItem("Light palette"):
            TextEditor_SetPalette(editor, TextEditor_GetLightPalette())
          #if igMenuItem("Mariana palette"):
          #  TextEditor_SetPalette(editor, TextEditor_GetMarianaP)
          #if igMenuItem("Retro blue palette", "Ctrl-B", nil, true):
          #  TextEditor_SetPalette(editor, TextEditor_GetRetroBlue)

      #let langNames = ["None".cstring, "Cpp", "C", "Cs", "Python", "Lua", "Json", "Sql", "AngelScript", "Glsl", "Hlsl"]
      igText("%6d/%-6d %6d lines  | %s | %s | %s | %s", curPos.line + 1, curPos.column + 1, TextEditor_GetLineCount(editor),
        if TextEditor_IsOverwriteEnabled(editor): "Ovr".cstring else: "Ins".cstring,
        if TextEditor_CanUndo(editor): "*".cstring else: " ".cstring, TextEditor_GetLanguageName(editor), fileName.cstring)

      igPushFont(textFont, 0.0)
      TextEditor_Render(editor, "texteditor", border = false, size = ImVec2_c(x: 0, y: 0))
      igPopFont()

    #--------
    # render
    #--------
    render(win)

    if fQuit:
      win.shouldClose = true # Exit program

  #### end while

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title = "ImGui Window")
  defer: destroyImGui(win)

  discard setupFonts()

  gui_main(win)

#------
# main
#------
main()
