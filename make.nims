import std/[os,strutils]

var projDirs = @[
"glfw_opengl3",
"glfw_opengl3_base",
"glfw_opengl3_filedialog",
"glfw_opengl3_iconfont_viewer",
"glfw_opengl3_image_load",
"glfw_opengl3_image_save",
"glfw_opengl3_imColorTextEdit",
"glfw_opengl3_imgui_toggle",
"glfw_opengl3_imguizmo",
"glfw_opengl3_imknobs",
"glfw_opengl3_imnodes",
"glfw_opengl3_implot",
"glfw_opengl3_implot3d",
"glfw_opengl3_imspinner",
"glfw_opengl3_imgui_markdown",
"glfw_opengl3_jp",
"sdl2_opengl3",
"sdl2_renderer",
"sdl3_opengl3",
"sdl3_renderer",
"fontx2v",
]

#-------------
# compileProj
#-------------
proc compileProj(cmd:string) =
  var options = ""

  for dir in projDirs:
    if dir.dirExists:
      withDir(dir):
        if cmd == "clean":
          options = join([options,"--no-print-directory"]," ")
        exec("make $# $#" % [options,cmd])

#------
# main
#------
var cmd:string
if commandLineParams().len >= 2:
  cmd = commandLineParams()[1]
compileProj(cmd)
