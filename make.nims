import std/[os,strutils]

var projDirs = @[
"glfw_opengl3",
"glfw_opengl3_base",
"glfw_opengl3_filedialog",
"glfw_opengl3_iconfont_viewer",
"glfw_opengl3_image_load",
"glfw_opengl3_image_save",
"glfw_opengl3_implot",
"glfw_opengl3_imguizmo",
"glfw_opengl3_imknobs",
"glfw_opengl3_imnodes",
"glfw_opengl3_jp",
"sdl2_opengl3",
"fontx2v",
]

when defined(windows):
  projDirs.add "sdl3_opengl3"

#-------------
# compileProj
#-------------
proc compileProj(cmd:string) =
  var options = ""
  #options =  join([options,"--no-print-directory"]," ")

  for dir in projDirs:
    if dir.dirExists:
      withDir(dir):
        exec("make $# $#" % [options,cmd])

#------
# main
#------
var cmd:string
if commandLineParams().len >= 2:
  cmd = commandLineParams()[1]
compileProj(cmd)