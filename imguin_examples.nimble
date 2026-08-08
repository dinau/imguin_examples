# Package

version       = "1.92.9.0"
author        = "dinau"
description   = "The examples for ImGuin that wrapper for ImGui libraries with Nim."
license       = "MIT"
srcDir        = "src"
skipDirs      = @[""]

# Dependencies

requires "imguin >= 1.92.9.0"
requires "sdl3_nim >= 3.4.2.0"
requires "sdl2_nim"
requires "nimgl"
requires "stb_image"
requires "tinydialogs"
requires "glfw"
requires "opengl"
requires "https://github.com/DanielBelmes/VulkanNim#head"
requires "https://github.com/Anuken/staticglfw"
requires "naylib"

task all,"Build all examples":
  exec("nimble dep")
  exec("nim make.nims")

task dep,"Install dependecies":
  exec("nimble install -d")
  echo "Updated"
