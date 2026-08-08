import std/strutils
include ../config.nims.common

#--------------------------------------------------------------------
# Emscripten support
# When targeting Emscripten, redirect the compiler/linker to emcc
# and set up the necessary flags.
# Technique based on: https://github.com/treeform/nim_emscripten_tutorial
#--------------------------------------------------------------------
switch "app", "gui" # dismiss background Window
switch "define", "release"
switch "opt", "size"

switch "define", "glfwStaticLib"

switch "warning", "HoleEnumConv:off" # for ImKnobs

# Libs
switch "define", "ImSpinner"
switch "define", "ImKnobs"
switch "define", "ImPlot"
switch "define", "ImPlot3D"

when defined(emscripten):
  switch("nimcache", ".nimcache_wasm")
  when true: # WebGL 2.0 / ES3
    switch("define", "OPENGL_ES3")
    switch("passC", "-DIMGUI_IMPL_OPENGL_ES3")
    switch("passL", " -sMAX_WEBGL_VERSION=2")
    switch("passL", " -sMIN_WEBGL_VERSION=2")
  else: # WebGL 1.0 / ES2
    switch("passC", "-DIMGUI_IMPL_OPENGL_ES2")
    switch("passL", " -s USE_WEBGL2=0")
    switch("passL", " -s FULL_ES2=1")

  #switch("passC", "-DEMSCRIPTEN_USE_PORT_CONTRIB_GLFW3")
  switch("passC","-sUSE_GLFW=3")
  switch("passL","-sUSE_GLFW=3")
  # emcc acts as both compiler and linker
  switch("clang.exe", "emcc")
  switch("clang.linkerexe", "emcc")
  # Common settings
  switch("threads", "off")
  switch("os", "linux") # Emscripten pretends to be Linux
  switch("cpu", "wasm32")
  switch("cc", "clang")
  switch("gc", "arc") # arc works well on exotic platforms
  switch("exceptions", "goto") # goto exceptions also work well
  switch("define", "noSignalHandler") # Emscripten doesn't support signal handlers
  switch("passL", "-o " & projectName() & ".html" &
    " --shell-file shell_minimal.html" &
    " -s WASM=1" &
    " -s NO_EXIT_RUNTIME=0" &
    " -s ASSERTIONS=1" &
    " -sUSE_GLFW=3" &
    " -o wasm/index.html" &
    " --preload-file ../utils/fonticon/fa6/fa-solid-900.ttf@../utils/fonticon/fa6/fa-solid-900.ttf" &
    " --preload-file img/animal_paradise-480.gif" &
    " --preload-file res/img/n.png" &
    " -s ALLOW_MEMORY_GROWTH=0 -s INITIAL_MEMORY=67108864" &
    " --preload-file ../licenses_window/resources/licenses/cimgui/LICENSE@../licenses_window/resources/licenses/cimgui/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimgui/imgui/LICENSE.txt@../licenses_window/resources/licenses/cimgui/imgui/LICENSE.txt" &
    " --preload-file ../licenses_window/resources/licenses/cimgui_toggle/LICENSE@../licenses_window/resources/licenses/cimgui_toggle/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimgui_toggle/libs/imgui_toggle/LICENSE@../licenses_window/resources/licenses/cimgui_toggle/libs/imgui_toggle/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/CImGuiFileDialog/libs/ImGuiFileDialog/stb/LICENSE@../licenses_window/resources/licenses/CImGuiFileDialog/libs/ImGuiFileDialog/stb/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimgui-knobs/LICENSE@../licenses_window/resources/licenses/imgui-knobs/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimgui-knobs/imgui-knobs/LICENSE@../licenses_window/resources/licenses/cimgui-knobs/imgui-knobs/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimplot/LICENSE@../licenses_window/resources/licenses/cimplot/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimplot/implot/LICENSE@../licenses_window/resources/licenses/cimplot/implot/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/cimplot3d/dummy.txt@../licenses_window/resources/licenses/cimplot3d/dummy.txt" &
    " --preload-file ../licenses_window/resources/licenses/cimplot3d/implot3d/LICENSE@../licenses_window/resources/licenses/cimplot3d/implot3d/LICENSE" &
    " --preload-file ../licenses_window/resources/licenses/fonticon/fa6//LICENSE.txt@../licenses_window/resources/licenses/fonticon/fa6/LICENSE.txt" &
    " --preload-file ../licenses_window/resources/licenses/imspinner/LICENSE.txt@../licenses_window/resources/licenses/imspinner/LICENSE.txt " &
    " --preload-file ./fonts/ProggyClean.ttf@./fonts/ProggyClean.ttf "
    )
else:
  switch("nimcache", ".nimcache_app")
