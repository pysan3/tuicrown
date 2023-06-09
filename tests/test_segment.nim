import std/tempfiles
import std/colors
import std/os
import std/terminal
import std/strutils
import std/sequtils
import std/unittest

import tuicrown/[tuisegment, tuicontrol, tuistyles]
import file_test_utils

test "TuiControl":
  check newTuiControl(BELL).escape() == "\x07".escape()
  check newTuiControl(CARRIAGE_RETURN).escape() == "\x0D".escape()
  check newTuiControl(HOME).escape() == "\x1B[H".escape()
  check newTuiControl(CLEAR).escape() == "\x1B[2J".escape()
  check newTuiControl(ENABLE_ALT_SCREEN).escape() == "\x1B[?1049h".escape()
  check newTuiControl(DISABLE_ALT_SCREEN).escape() == "\x1B[?1049l".escape()
  check newTuiControl(SHOW_CURSOR).escape() == "\x1B[?25h".escape()
  check newTuiControl(HIDE_CURSOR).escape() == "\x1B[?25l".escape()
  check newTuiControl(CURSOR_UP).escape() == "\x1B[1A".escape()
  check newTuiControl(CURSOR_DOWN).escape() == "\x1B[1B".escape()
  check newTuiControl(CURSOR_FORWARD).escape() == "\x1B[1C".escape()
  check newTuiControl(CURSOR_BACKWARD).escape() == "\x1B[1D".escape()
  check newTuiControl(ERASE_IN_LINE).escape() == "\x1B[2K".escape()
  check newTuiControl(CURSOR_MOVE_TO_COLUMN).escape() == "\x1B[2G".escape()
  check newTuiControl(CURSOR_MOVE_TO).escape() == "\x1B[2;2H".escape()
  check newTuiControl(SET_WINDOW_TITLE, "Title").escape() == "\x1B]0;Title\x07".escape()

test "TuiStyles new":
  var basic = newTuiStyles()
  check basic.fgColors.len() == 0
  check basic.fgColor.isNone()
  check basic.bgColors.len() == 0
  check basic.bgColor.isNone()
  check basic.styles.len() == 0

test "TuiStyles":
  check $newTuiStyles() == """[]"""
  check $newTuiStyles(@[styleBright]) == """[st: @[styleBright]]"""
  check $newTuiStyles(fgRed) == """[fg: (kind: TuiForegroundColorKind, TuiForegroundColorData: fgRed)]"""
  check $newTuiStyles(colBlue) == """[fg: (kind: TuiFGColorKind, TuiFGColorData: #0000FF)]"""
  check $newTuiStyles(fgRed, colBlue) == """[bg: (kind: TuiBGColorKind, TuiBGColorData: #0000FF), fg: (kind: TuiForegroundColorKind, TuiForegroundColorData: fgRed)]"""

test "TuiStyles operations":
  var st = newTuiStyles()
  check st == newTuiStyles()
  st.fgColor = fgNone()
  check st == newTuiStyles()
  st.fgColor = newTuiStyles(fgRed).fgColor
  check st == newTuiStyles(fgRed)
  st.bgColor = newTuiStyles(bgColor = colBlue).bgColor
  check st == newTuiStyles(fgRed, colBlue)

test "TuiStyles copy/deepCopy":
  var st = newTuiStyles(fgBlue)
  st.fgColor = newTuiStyles(fgRed).fgColor
  var origin = newTuiStyles(fgRed)
  var shallow = st.copy()
  shallow -= newTuiStyles(fgRed)
  check shallow == newTuiStyles()
  check st == origin
  var deep = st.deepCopy()
  deep -= newTuiStyles(fgRed)
  check deep == newTuiStyles(fgBlue)
  check st == origin

test "TuiSegment new":
  var basic = newTuiSegment()
  check basic.text == ""
  check basic.style == newTuiStyles()
  check basic.controls.len == 0

test "TuiSegment addStyle/delStyle":
  var seg = newTuiSegment("test", newTuiStyles(bgColor = colBlue))
  check seg.style == newTuiStyles(bgColor = colBlue)
  seg.addStyle(fgRed, colRed)
  check seg.style == newTuiStyles(fgRed, colRed)
  seg.addStyle(colRed)
  check seg.style == newTuiStyles(colRed, colRed)
  seg.delStyle(colRed, colRed)
  check seg.style == newTuiStyles(fgRed, colBlue)
  while seg.style.bgColor.isSome:
    seg.delStyle(bgColor = seg.style.bgColor)
  check seg.style == newTuiStyles(fgRed)

test "TuiStyles from string":
  check newTuiStyles(nil, "fgRed") == newTuiStyles(fgRed)
  check newTuiStyles(nil, "fg:red") == newTuiStyles(fgRed)
  check newTuiStyles(nil, "bg:red") == newTuiStyles(bgColor = bgRed)
  check newTuiStyles(nil, "fg:gray") == newTuiStyles(color = colGray)
  check newTuiStyles(nil, "bold") == newTuiStyles(styles = @[styleBlink])
  check newTuiStyles(nil, "u") == newTuiStyles(styles = @[styleUnderscore])

test "TuiStyles extend from string":
  var st = newTuiStyles(nil, "fgRed")
  st = newTuiStyles(st, "bg:gray")
  check st == newTuiStyles(fgRed, colGray)
  st = newTuiStyles(st, "bold")
  check st == newTuiStyles(fgRed, colGray, @[styleBlink])
  st = newTuiStyles(st, "i")
  check st == newTuiStyles(fgRed, colGray, @[styleBlink, styleItalic])

test "TuiSegment from string":
  var segseq = fromString("[red]hoge")
  var correct = @[newTuiSegment("hoge", newTuiStyles(fgRed))]
  check segseq.len() == correct.len()
  for (seg, cor) in zip(segseq, correct):
    check seg == cor

testParse "no content results to empty string":
  "" -> ""

testParse "single word":
  "word" -> "word" & ansiResetCode

testParse "formatter: [fgRed]":
  "[fgRed]red[fgGreen]green[fgYellow]yellow[/]" -> "\x1B[31mred\x1B[0m\x1B[32mgreen\x1B[0m\x1B[33myellow" & ansiResetCode

testParse "formatter: [fgRed]":
  "[fgRed]text in red[/] and [fgBlue bgWhite]blue[/]" -> "\x1B[31mtext in red\x1B[0m and \x1B[0m\x1B[47m\x1B[34mblue" & ansiResetCode

testParse "formatter: [colRed]":
  "[colRed]text in pure red" -> "text in pure red" & ansiResetCode
