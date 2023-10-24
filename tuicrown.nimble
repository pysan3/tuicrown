# Package

version = "0.8.1" # {x-release-please-version}
author = "pysan3"
description = "Tuicrown is a Nim library for rich text and beautiful formatting in the terminal."
license = "MPL-2.0"
srcDir = "."
skipDirs = @["tests", "tmp"]

# Dependencies

requires "nim >= 2.0.0"
requires "fungus"
requires "regex >= 0.21.0"
requires "nimoji >= 0.1.5"
