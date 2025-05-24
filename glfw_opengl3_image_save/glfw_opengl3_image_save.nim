# Compiling:
# nim c glfw_opengl3_image_load

import std/[os, strformat, strutils]
import ../utils/[appImGui, infoWindow]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 900

#--- Constants
const SaveImageName = "ImageSaved"

#--- Global vars
var
  imageExt:string
  imageFormatTbl = [(kind:"JPEG 90%",ext:".jpg"), ("PNG",".png"), ("BMP",".bmp"), ("TGA",".tga")]

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="ImGui image save demo")
  defer: destroyImGui(win)

  var
    showFirstWindow = true
    counter = 0

  #-------------
  # Load image
  #-------------
  var
    textureId: GLuint
    textureWidth = 0
    textureHeight = 0
  var ImageName = os.joinPath(os.getAppDir(),"himeji-400.jpg")
  loadTextureFromFile(ImageName, textureId, textureWidth,textureHeight)
  defer: glDeleteTextures(1, addr textureId)

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    infoWindow(win)

    var svName:string

    # show a simple window that we created ourselves.
    if showFirstWindow:
      igBegin("Select format of the save image", addr showFirstWindow, 0)
      defer: igEnd()
      #
      #-- Save button for capturing window image
      igPushIDInt(0)
      igPushStyleColorVec4(ImGuiCol_Button.cint,        vec4(0.7, 0.7, 0.0, 1.0))
      igPushStyleColorVec4(ImGuiCol_ButtonHovered.cint, vec4(0.8, 0.8, 0.0, 1.0))
      igPushStyleColorVec4(ImGuiCol_ButtonActive.cint,  vec4(0.9, 0.9, 0.0, 1.0))
      igPushStyleColorVec4(ImGuiCol_Text.cint,          vec4(0.0, 0.0, 0.0, 1.0))

      # Image save button
      imageExt = imageFormatTbl[win.ini.imageSaveFormatIndex].ext
      svName = fmt"{SaveImageName}_{counter:05}{imageExt}"
      if igButton("Save Image", vec2(0.0f, 0.0f)):
        let wkSize = igGetMainViewport().Worksize
        saveImage(svName,0, 0, wkSize.x.int, wkSize.y.int) # --- Save Image !
      igPopStyleColor(4)
      igPopID()

      #-- Show tooltip help
      setTooltip("Save to \"$#\"" % [svName])
      counter.inc
      #-- End Save button for window image
      igSameLine(0.0,-1.0)

      #-- ComboBox: Select save image format
      igSetNextItemWidth(100)
      if igBeginCombo("##".cstring, imageFormatTbl[win.ini.imageSaveFormatIndex].kind.cstring, 0):
        for n,val in imageFormatTbl:
          var is_selected = (win.ini.imageSaveFormatIndex == n)
          if igSelectableBoolPtr(val.kind.cstring, is_selected.addr, 0, vec2(0.0, 0.0)):
            if is_selected:
              igSetItemDefaultFocus()
            win.ini.imageSaveFormatIndex = n
        igEndCombo()
      setTooltip("Select image format")

    # Show image load window
    block:
      igBegin("Image load test", nil, 0)
      defer: igEnd()
      # Load image
      let
        size = vec2(textureWidth, textureHeight)
        uv0 = vec2(0, 0)
        uv1 = vec2(1, 1)
        tint_col   = vec4(1, 1, 1, 1)
        border_col = vec4(0, 0, 0, 0)
      var
        imageBoxPosTop:ImVec2
        imageBoxPosEnd:ImVec2
      igGetCursorScreenPos(addr imageBoxPosTop) # Get absolute pos.
      igImage(cast[ImTextureID](textureId), size, uv0, uv1) #, tint_col, border_col);
      igGetCursorScreenPos(addr imageBoxPosEnd) # Get absolute pos.
      #
      if igIsItemHovered(ImGui_HoveredFlags_DelayNone.ImGuiHoveredFlags):
        zoomGlass(textureId, textureWidth, imageBoxPosTop, imageBoxPosEnd)

    render(win)
    if not showFirstWindow :
      win.handle.setWindowShouldClose(true) # End program

  #### end while

#------
# main
#------
main()
