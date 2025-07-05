# Package

version       = "1.92.0.0"
author        = "dinau"
description   = "The examples for ImGuin that wrapper for ImGui libraries with Nim language."
license       = "MIT"
srcDir        = "src"
skipDirs      = @[""]


# Dependencies

requires "imguin == 1.92.0.0"
requires "nim >= 2.0.16"
requires "sdl3_nim == 3.2.16.0"
requires "nimgl == 1.3.2"
requires "sdl2_nim == 2.0.14.3"
requires "stb_image == 2.5"
requires "tinydialogs == 1.1.0"
requires "glfw == 3.4.0.4"
requires "opengl"


task all,"Build all examples":
  #let cmd = "nim c -d:strip -o:$# $# $#.nim" % [TARGET.toEXE,Opts,"src/" & TARGET]
  #echo cmd
  exec("nimble dep")
  exec("nim make.nims")

task dep,"Install dependecies":
  echo "Updated"
