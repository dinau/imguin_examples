# Package

version       = "1.91.6.11"
author        = "dinau"
description   = "The examples for ImGuin that wrapper for ImGui libraries with Nim language."
license       = "MIT"
srcDir        = "src"
skipDirs      = @[""]


# Dependencies

requires "nim >= 2.0.14"
requires "https://github.com/dinau/imguin == 1.91.6.11"
requires "https://github.com/dinau/sdl3_nim >= 0.6"
requires "nimgl == 1.3.2"
requires "sdl2_nim == 2.0.14.3"
requires "stb_image == 2.5"
requires "tinydialogs == 1.1.0"
requires "glfw == 3.4.0.4"


task all,"Build all examples":
  #let cmd = "nim c -d:strip -o:$# $# $#.nim" % [TARGET.toEXE,Opts,"src/" & TARGET]
  #echo cmd
  exec("nimble dep")
  exec("nim make.nims")

task dep,"Install dependecies":
  echo "Updated"
