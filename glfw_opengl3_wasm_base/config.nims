import std/strutils
#--------------------------------------------------------------------
# Emscripten support
# When targeting Emscripten, redirect the compiler/linker to emcc
# and set up the necessary flags.
# Technique based on: https://github.com/treeform/nim_emscripten_tutorial
#--------------------------------------------------------------------
switch "app","gui" # dismiss background Window
switch "define",   "release"
switch "opt",      "size"

switch "define", "glfwStaticLib"

switch "warning","HoleEnumConv:off" # for ImKnobs

# Libs
switch "define", "ImSpinner"
switch "define", "ImKnobs"
switch "define", "ImPlot"
switch "define", "ImPlot3D"

when defined(emscripten):
  switch("nimcache", ".nimcache_wasm")
  when true:
    switch "define", "OPENGL_ES3"
    switch("passC", "-DIMGUI_IMPL_OPENGL_ES3")
  else:
    switch("passC", "-DIMGUI_IMPL_OPENGL_ES2")

  switch("passC", "-DEMSCRIPTEN_USE_PORT_CONTRIB_GLFW3")
  {.passC: "--use-port=contrib.glfw3".}
  # emcc acts as both compiler and linker
  when defined(windows):
    switch("clang.exe", "emcc.bat")
    switch("clang.linkerexe", "emcc.bat")
    #
  else:
    switch("clang.exe", "emcc")
    switch("clang.linkerexe", "emcc")
  # Common settings
  switch("threads", "off")
  switch("os", "linux")         # Emscripten pretends to be Linux
  switch("cpu", "wasm32")
  switch("cc", "clang")
  switch("gc", "arc")           # arc works well on exotic platforms
  switch("exceptions", "goto")  # goto exceptions also work well
  switch("define", "noSignalHandler") # Emscripten doesn't support signal handlers
  switch("passL", "-o " & projectName() & ".html" &
    " --shell-file shell_minimal.html" &
    " -s USE_WEBGL2=1" &
    " -s FULL_ES3=1" &
    " -s WASM=1" &
    " -s NO_EXIT_RUNTIME=0" &
    " -s ASSERTIONS=1" &
    " --use-port=contrib.glfw3" &
    " --preload-file ../utils/fonticon/fa6/fa-solid-900.ttf@../utils/fonticon/fa6/fa-solid-900.ttf" &
    " --preload-file img/animal_paradise-480.gif" &
    " --preload-file res/img/n.png" &
    " -s ALLOW_MEMORY_GROWTH=1"
    )
else:
  switch "nimcache", ".nimcache_app"
