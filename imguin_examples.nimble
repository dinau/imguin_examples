# Package

version       = "1.91.6.7"
author        = "dinau"
description   = "The examples for ImGuin that wrapper for ImGui libraries with Nim language."
license       = "MIT"
srcDir        = "src"
skipDirs      = @[""]


# Dependencies

requires "nim >= 2.0.14"
requires "https://github.com/dinau/imguin >= 1.91.6.8"
requires "tinydialogs == 1.1.0"


task all,"Build all examples":
  #let cmd = "nim c -d:strip -o:$# $# $#.nim" % [TARGET.toEXE,Opts,"src/" & TARGET]
  #echo cmd
  exec("nim make.nims")

task dep,"Install dependecies":
  echo "Updated"
