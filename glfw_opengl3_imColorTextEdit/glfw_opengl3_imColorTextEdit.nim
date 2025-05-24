# Compiling:
# nim c -d:ImColorTextEdit glfw_opengl3_imColorTextEdit.nim

# Refer to :
#            https://github.com/sonoro1234/LuaJIT-ImGui/blob/docking_inter/examples/CTE_sample.lua
#            https://github.com/sonoro1234/LuaJIT-ImGui
#            https://github.com/BalazsJako/ColorTextEditorDemo/blob/master/main.cpp
#            https://github.com/BalazsJako/ColorTextEditorDemo
import std/[paths]
import ../utils/[appImGui, infoWindow, setupFonts]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

const MainWinWidth = 1024
const MainWinHeight = 800

# This is a programing font. https://github.com/yuru7/NOTONOTO
const fontFullPath = "./fonts/notonoto_v0.0.3/NOTONOTO-Regular.ttf"
const fileName = "main.cpp"

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui Window")
  defer: destroyImGui(win)

  var strText = readFile(fileName)
  let editor = TextEditor_TextEditor()
  TextEditor_SetLanguageDefinition(editor, LanguageDefinitionId.Cpp)
  TextEditor_SetText(editor, strText.cstring)

  TextEditor_SetPalette(editor, Light)

  var mLine:cint
  var mColumn:cint
  var fQuit = false

  let pio = igGetIO()

  # Setup programing fonts
  const textPoint = 14.5
  let   textFont  = pio.Fonts.ImFontAtlas_AddFontFromFileTTF(fontFullPath.cstring, textPoint.point2px, nil, pio.Fonts.ImFontAtlas_GetGlyphRangesJapanese());

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    infoWindow(win)

    TextEditor_GetCursorPosition(editor, addr mLine, addr mColumn)
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
        #
        #if igBeginMenu("Edit", true):
        #  defer: igEndMenu()
        #  var ro = TextEditor_IsReadOnlyEnabled(editor)
        #  if igMenuItem("Read-only mode", nil, addr ro):
        #    TextEditor_SetReadOnlyEnabled(editor,ro)
        #  igSeparator()
        #  #
        #  if igMenuItem("Undo", "ALT-Backspace", nil, not ro and TextEditor_CanUndo(editor)):
        #    TextEditor_Undo(editor,1)
        #  if igMenuItem("Redo", "Ctrl-Y"       , nil, not ro and TextEditor_CanRedo(editor)):
        #    TextEditor_Redo(editor,1)
        #  igSeparator()
        #  #
        #  if igMenuItem("Copy", "Ctrl-C",        nil, TextEditor_AnyCursorHasSelection(editor)):
        #    TextEditor_Copy(editor)
        #  if igMenuItem("Cut", "Ctrl-X",         nil, not ro and TextEditor_AnyCursorHasSelection(editor)):
        #    TextEditor_Cut(editor)
        #  if igMenuItem("Paste", "Ctrl-V",       nil, not ro and igGetClipboardText() != nil):
        #    TextEditor_Paste(editor)
        #  igSeparator();
        #  if igMenuItem("Select all",   "Ctrl-A",         nil, true):
        #    TextEditor_SelectAll(editor)
        # #

        #if igBeginMenu("Theme", true):
        #  defer: igEndMenu()
        #  if igMenuItem("Dark palette"):
        #    TextEditor_SetPalette(editor, Dark)
        #  if igMenuItem("Light palette"):
        #    TextEditor_SetPalette(editor,Light)
        #  if igMenuItem("Mariana palette"):
        #    TextEditor_SetPalette(editor,Mariana)
        #  if igMenuItem("Retro blue palette", "Ctrl-B", nil, true):
        #    TextEditor_SetPalette(editor,RetroBlue)
        #--

      let langNames = ["None".cstring, "Cpp", "C", "Cs", "Python", "Lua", "Json", "Sql", "AngelScript", "Glsl", "Hlsl"]
      igText("%6d/%-6d %6d lines  | %s | %s | %s | %s" , mLine + 1, mColumn + 1, TextEditor_GetLineCount(editor),
        if TextEditor_IsOverwriteEnabled(editor): "Ovr".cstring else: "Ins".cstring,
        if TextEditor_CanUndo(editor): "*".cstring else: " ".cstring, langNames[TextEditor_GetLanguageDefinition(editor).cuint], fileName.cstring)

      igPushFont(textFont)
      TextEditor_Render(editor, "texteditor", false, vec2(0,0), false)
      igPopFont()

    #--------
    # render
    #--------
    render(win)

    if fQuit:
      win.handle.setWindowShouldClose(true) # Exit program

  #### end while

#------
# main
#------
main()
