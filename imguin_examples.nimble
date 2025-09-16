# Package

version       = "1.92.2.1b"
author        = "dinau"
description   = "The examples for ImGuin that wrapper for ImGui libraries with Nim language."
license       = "MIT"
srcDir        = "src"
skipDirs      = @[""]


# Dependencies

requires "imguin == 1.92.2.1"
requires "sdl3_nim == 3.2.16.0"


task all,"Build all examples":
  #let cmd = "nim c -d:strip -o:$# $# $#.nim" % [TARGET.toEXE,Opts,"src/" & TARGET]
  #echo cmd
  exec("nimble dep")
  exec("nim make.nims")

task dep,"Install dependecies":
  echo "Updated"
