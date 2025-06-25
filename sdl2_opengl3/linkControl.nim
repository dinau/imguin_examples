import strformat
switch "app","gui" # dismiss background Window

#---------------------------------------
# Select static link or shared/dll link
#---------------------------------------
const STATIC_LINK_CC = true
const STATIC_LINK_SDL = false  # sdl2_nim library links only dynamic library.

when defined(windows):
  if TC == "vcc":
    switch "passL","d3d9.lib kernel32.lib user32.lib gdi32.lib winspool.lib"
    switch "passL","comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib"
    switch "passL","uuid.lib odbc32.lib odbccp32.lib"
    switch "passL","imm32.lib"
  else: # gcc, clang etc
    when STATIC_LINK_CC:
      switch "passC", "-static"
      switch "passL", "-static"
    when STATIC_LINK_SDL: # For SDL2 static link
      switch "passL","-lm"
      switch "passL",fmt"-L{SDL_LIB_DIR}"
      switch "passL","-lSDL2main"
      switch "passL","-lSDL2"
      switch "passL","-ladvapi32"
      switch "passL","-ldinput8"
      switch "passL","-lgdi32"
      switch "passL","-limm32"
      switch "passL","-lkernel32"
      switch "passL","-lmingw32"
      switch "passL","-lole32"
      switch "passL","-loleaut32"
      switch "passL","-lsetupapi"
      switch "passL","-lshell32"
      switch "passL","-luser32"
      switch "passL","-luuid"
      switch "passL","-lversion"
      switch "passL","-lwinmm"
    else:
      switch "passL","-lSDL2.dll"
      switch "passL","-limm32"
