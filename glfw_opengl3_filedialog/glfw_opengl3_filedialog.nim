# Compiling:
# nim c -d:ImGuiFileDialogEnable glfw_opengl3_filedialog


# Specify custom icon header file
{.passC:"-I.".}
{.passC:"-I../utils/fonticon".}
{.passC:"-DCUSTOM_IMGUIFILEDIALOG_CONFIG=<customIconFont.h>".}

import ../utils/appImGui
import ../utils/[infoWindow, themes/themeGold]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource

const MainWinWidth = 1024
const MainWinHeight = 800

# Forward definitions
proc setFileStyle*(cfd: ptr ImGuiFileDialog)

template copyToString(sName:string, pName:cstring) =
  if not isNil pName:
    defer: free(pName)
    var sz = pName.len
    sName = newString(sz)
    copyMem(addr sName[0], pName, sz)

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="FileDialog demo")
  defer: destroyImGui(win)
  let theme = Theme.Classic
  setTheme(theme)

  var
    sFnameSelected{.global.}:string

  var
    sFilePathName:string
    sFileDirPath:string
    sFilter:string
    sDatas:string
    themeSave:Theme

  #------------------------------
  # Create FileDialog object
  #------------------------------
  let cfd = IGFD_Create()
  defer: IGFD_Destroy(cfd) # destroy ImGuiFileDialog
  setFileStyle(cfd)

  #-----------
  # main loop
  #-----------
  while not win.handle.windowShouldClose:
    glfwPollEvents()
    newFrame()

    infoWindow(win)

    block:
      igBegin("FileOpenDialog demo", nil, 0)
      defer: igEnd()

      # Show file open dialog
      if igButton("Open file", vec2(100, 50)):
        #---------------------------
        # Triggered FileOpenDialog
        #---------------------------
        var config = IGFD_FileDialog_Config_Get()
        config.path  = "."
        config.flags = ImGuiFileDialogFlags_Modal.int32 or
                       ImGuiFileDialogFlags_ShowDevicesButton.int32 or
                       ImGuiFileDialogFlags_CaseInsensitiveExtentionFiltering.int32
                     #  ImGuiFileDialogFlags_ConfirmOverwrite.int32
        IGFD_OpenDialog(cfd,
                        "filedlg".cstring,                             # dialog key (make it possible to have different treatment reagrding the dialog key
                        (ICON_FA_FILE &  " Open a File").cstring,      # dialog title
                        "all (*){.*},c files(*.c *.h){.c,.h}".cstring, # dialog filter syntax : simple => .h,.c,.pp, etc and collections : text1{filter0,filter1,filter2}, text2{filter0,filter1,filter2}, etc..
                                                                       # dialog filter syntax : if one wants to select directory then set nil
                        config)                                        # the file dialog config
        themeSave = getTheme(win)
        themeGold()
      setTooltip("[Open file]") # Show hint

      #------------------------------
      # Start display FileDialog
      #------------------------------
      let ioptr = igGetIO()
      let maxSize = vec2(ioptr.DisplaySize.x * 0.8, ioptr.DisplaySize.y * 0.8)
      let minSize = vec2(maxSize.x * 0.25,  maxSize.y * 0.25)

      if IGFD_DisplayDialog(cfd, "filedlg".cstring, ImGuiWindowFlags_NoCollapse.ImGuiWindowFlags, minSize, maxSize):
        defer: IGFD_CloseDialog(cfd)
        if IGFD_IsOk(cfd) : # result ok
          var cstr:cstring
          cstr = IGFD_GetFilePathName(cfd, IGFD_ResultMode_AddIfNoFileExt.IGFD_ResultMode)
          copyToString(sFilePathName, cstr)
          cstr = IGFD_GetCurrentPath(cfd)
          copyToString(sFileDirPath, cstr)
          cstr = IGFD_GetCurrentFilter(cfd)
          copyToString(sFilter, cstr)
          # here convert from string because a string was passed as a userDatas, but it can be what you want
          let pDatas = IGFD_GetUserDatas(cfd)
          if not isNil pDatas:
            cstr = cast[cstring](pDatas)
            copyToString(sDatas, cstr)
          # TODO
          #var csel = IGFD_GetSelection(cfd, IGFD_ResultMode_KeepInputFile.IGFD_ResultMode) # multi selection
          #defer: IGFD_Selection_DestroyContent(addr csel)
          #echo "Selection :\n"
          #for i in 0..<csel.count:
            #let table = cast[UncheckedArray[IGFD_Selection_Pair]](csel.table)
          #  # echo "($#) FileName $# => path $#\n" % [$i, $csel.table[i].fileName, $csel.table[i].filePathName]
        setTheme(themeSave)
      # end DisplayDialog

      igText("Selected file = %s", sFilePathName.cstring)
      igText("Dir           = %s", sFileDirPath.cstring)
      igText("Filter        = %s", sFilter.cstring)
      igText("Datas         = %s", sDatas.cstring)

    #
    render(win)

  #### end while

#------
# main
#------
main()

#-----------------
#--- setFileStyle
#-----------------
proc setFileStyle*(cfd: ptr ImGuiFileDialog) =
  let clGreen  = vec4(0f,    1f,          0f,   1f)
  let clYellow = vec4(1f,    1f,          0f,   1f)
  let clOrange = vec4(1f,    165.0/255.0, 0f,   1f)
  let clWhite2 = vec4(0.98, 0.98,         1f,   1f)
  let clWhite  = vec4(1f,    0f,          1f,   1f)
  let clCyan   = vec4(0f,    1f,          1f,   1f)
  let clPurple = vec4(255f,  51/255.0,   255f,  1f)

  let pFont = igGetDefaultFont()
  let byExt = IGFD_FileStyleByExtention.IGFD_FileStyleFlags
  IGFD_SetFileStyle(cfd, byExt , ".exe",      clCyan,   ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, byExt , ".nim",      clPurple, ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, byExt , ".c",        clGreen,  ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, byExt , ".h",        clYellow, ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, byExt , ".txt",      clWhite2, ICON_FA_FILE_LINES, pFont)
  IGFD_SetFileStyle(cfd, byExt , ".bat",      clWhite2, ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, byExt , ".ini",      clWhite2, ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, byExt , ".md",       clWhite,  ICON_FA_FILE,       pFont)
  #IGFD_SetFileStyle(cfd, byExt , "(.+[.].+)", clWhite2, ICON_FA_FILE,       pFont)
  IGFD_SetFileStyle(cfd, IGFD_FileStyleByTypeDir.IGFD_FileStyleFlags , nil, clOrange, ICON_FA_FOLDER, pFont)
