import std/tempfiles
import std/colors
import std/os
import std/macros
import std/strutils
import std/options
import std/strformat
import std/unittest

import tuicrown/[tuisegment, tuicontrol, tuistyles]

# Test with tempfile
doAssertRaises(OSError): discard createTempFile("", "", "nonexistent")

proc parseString*(text: string): seq[TuiSegment] =
  fromString(text)

macro withFile*(head: untyped, body: untyped): untyped =
  let
    cfile = newIdentNode("cfile")
    path = newIdentNode("path")
  quote do:
    let (`cfile`, `path`) = createTempFile("`head`", "`head`")
    `body`
    `cfile`.close()
    `path`.removeFile()

proc getContent*(cfile: File): string =
  cfile.setFilePos(0)
  return readAll(cfile)

proc parseAndWrite*(cfile: File, text: string) =
  for seg in parseString(text):
    cfile.print(seg)

proc checkOrFail*(a, b: string) =
  if a != b:
    echo &"{a.escape=}"
    echo &"{b.escape=}"
  check a == b

macro compareEscape*(head: typed, body: untyped): untyped =
  let text = body[0][1]
  let output = body[0][2]
  quote do:
    echo `head` & ":"
    echo "  " & `text`.escape
    echo "  " & `output`.escape
    check `text` == `output`
    echo "  => \"" & `text` & "\""

macro testParse*(head: typed, body: untyped): untyped =
  let
    text = body[0][1]
    output = body[0][2]
  quote do:
    test `head`:
      withFile log:
        cfile.parseAndWrite(`text`)
        var content = cfile.getContent
        compareEscape `head`:
          content -> `output`

macro testConsole*(head: typed, body: untyped): untyped =
  runnableExamples:
    ## testConsole "Normal text":
    ##   "[colRed]text in pure red" -> "\x1B[38;2;255;0;0m\x1B[0m\x1B[38;2;255;0;0mtext in pure red" & endSeq
    test "Normal text":
      var pos = console.file.getFilePos()
      console.printWithOpt("", "", "[colRed]text in pure red")
      var cur = console.file.getFilePos()
      var content = getContent(console.file).substr(pos, cur - 1)
      compareEscape "Normal text":
        content -> "\x1B[38;2;255;0;0m\x1B[0m\x1B[38;2;255;0;0mtext in pure red" & endSeq
      console.file.setFilePos(pos)
  let
    text = body[0][1]
    output = body[0][2]
  quote do:
    test `head`:
      var pos = console.file.getFilePos()
      console.printWithOpt("", "", `text`)
      var cur = console.file.getFilePos()
      var content = getContent(console.file).substr(pos, cur - 1)
      compareEscape `head`:
        content -> `output`
      console.file.setFilePos(pos)
