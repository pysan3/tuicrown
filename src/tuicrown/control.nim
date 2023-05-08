import std/sequtils
import std/strutils
import std/strformat
import std/os
import std/sugar

import utils

type
  ControlType* = enum
    BELL = "\x07"
    CARRIAGE_RETURN = "\r"
    HOME = "\x1b[H"
    CLEAR = "\x1b[2J"
    ENABLE_ALT_SCREEN = "\x1b[?1049h"
    DISABLE_ALT_SCREEN = "\x1b[?1049l"
    SHOW_CURSOR = "\x1b[?25h"
    HIDE_CURSOR = "\x1b[?25l"
    CURSOR_UP = "A"
    CURSOR_DOWN = "B"
    CURSOR_FORWARD = "C"
    CURSOR_BACKWARD = "D"
    ERASE_IN_LINE = "K"
    CURSOR_MOVE_TO_COLUMN = "G"
    CURSOR_MOVE_TO = "H"
    SET_WINDOW_TITLE = "TITLE"
  TuiControl* = string

proc newTuiControl*(t: ControlType, title: string): TuiControl =
  &"\x1b]0;{title}\x07"

proc newTuiControl*(t: ControlType, args: seq[string]): TuiControl =
  newTuiControl(t, args.map((x: string) => $x).join(" "))

proc newTuiControl*(t: ControlType, args: seq[int]): TuiControl =
  if t <= HIDE_CURSOR:
    return $t
  elif t <= CURSOR_BACKWARD:
    let param = argsWithDefault(args, 0, 1)
    return &"\x1b[{param}{t}"
  elif t <= CURSOR_MOVE_TO_COLUMN:
    let param = argsWithDefault(args, 0, 1)
    return &"\x1b[{param + 1}{t}"
  elif t <= CURSOR_MOVE_TO:
    let
      x = argsWithDefault(args, 0, 1)
      y = argsWithDefault(args, 1, 1)
    return &"\x1b[{y + 1};{x + 1}{t}"
  else:
    var targs = args.map((x) => $x)
    if targs.len == 0:
      targs.add(getAppFilename().substr(getAppDir().len + 1))
      when declared(commandLineParams):
        for p in commandLineParams(): targs.add(p)
    return newTuiControl(t, targs)

proc newTuiControl*(t: ControlType, args: varargs[int]): TuiControl =
  return newTuiControl(t, args.toSeq)
