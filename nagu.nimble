# Package

version       = "0.1.0"
author        = "momeemt"
description   = "Nim Abstract OpenGL Utility"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.6.2"
requires "nimgl == 1.3.2"
requires "glm == 1.1.1"
requires "Palette == 0.2.1"

# Tasks

## https://qiita.com/SFITB/items/dceb1537e4086fa696d2
task test, "run all tests":
  exec "testament cat /"
