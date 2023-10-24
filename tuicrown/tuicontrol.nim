import std/sequtils
import std/strutils
import std/strformat
import std/os
import std/terminal

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
  TuiControl* = ref object of RootObj
    typ*: ControlType
    args*: seq[int]
    title*: string

proc newTuiControl*(t: ControlType, title: string): TuiControl =
  TuiControl(typ: t, title: title)

proc newTuiControl*(t: ControlType, args: seq[string]): TuiControl =
  newTuiControl(t, args.mapIt($it).join(" "))

proc newTuiControl*(t: ControlType, args: seq[int]): TuiControl =
  if t <= HIDE_CURSOR:
    return TuiControl(typ: t)
  elif t <= CURSOR_MOVE_TO_COLUMN:
    let param = argsWithDefault(args, 0, 1)
    return TuiControl(typ: t, args: @[param])
  elif t <= CURSOR_MOVE_TO:
    let
      x = argsWithDefault(args, 0, 1)
      y = argsWithDefault(args, 1, 1)
    return TuiControl(typ: t, args: @[x, y])
  else:
    var targs = args.mapIt($it)
    if targs.len == 0:
      targs.add(getAppFilename().substr(getAppDir().len + 1))
      when declared(commandLineParams):
        for p in commandLineParams(): targs.add(p)
    return newTuiControl(t, targs)

proc newTuiControl*(t: ControlType, args: varargs[int]): auto =
  newTuiControl(t, args.toSeq)

proc printToUnix*(self: TuiControl): string =
  if self.typ <= HIDE_CURSOR:
    return $self.typ
  elif self.typ <= CURSOR_BACKWARD:
    return &"\x1b[{self.args[0]}{self.typ}"
  elif self.typ <= CURSOR_MOVE_TO_COLUMN:
    return &"\x1b[{self.args[0] + 1}{self.typ}"
  elif self.typ <= CURSOR_MOVE_TO:
    return &"\x1b[{self.args[1] + 1};{self.args[0] + 1}{self.typ}"
  else:
    return &"\x1b]0;{self.title}\x07"

proc print*(f: File, self: TuiControl) =
  try:
    case self.typ:
    of CURSOR_BACKWARD:
      f.cursorBackward(self.args[0])
    of CURSOR_DOWN:
      f.cursorDown(self.args[0])
    of CURSOR_FORWARD:
      f.cursorForward(self.args[0])
    of CURSOR_UP:
      f.cursorUp(self.args[0])
    of HOME:
      f.eraseLine()
    of CLEAR:
      f.eraseScreen()
    of HIDE_CURSOR:
      f.hideCursor()
    of CURSOR_MOVE_TO:
      f.setCursorPos(self.args[0], self.args[1])
    of CURSOR_MOVE_TO_COLUMN:
      f.setCursorXPos(self.args[0])
    of SHOW_CURSOR:
      f.showCursor()
    else:
      assert(false, &"{self.typ} not supported by nim std/terminal. Fallback to Unix escape codes.")
  except Exception:
    f.write(self.printToUnix())

proc `$`*(self: TuiControl): string =
  self.printToUnix()

proc escape*(self: TuiControl): string =
  ($self).escape()

mainExamples:
  # These values are examples on Unix consoles.

  echo newTuiControl(BELL).escape() # ==> "\x07"
  echo newTuiControl(CARRIAGE_RETURN).escape() # ==> "\x0D"
  echo newTuiControl(HOME).escape() # ==> "\x1B[H"
  echo newTuiControl(CLEAR).escape() # ==> "\x1B[2J"
  echo newTuiControl(ENABLE_ALT_SCREEN).escape() # ==> "\x1B[?1049h"
  echo newTuiControl(DISABLE_ALT_SCREEN).escape() # ==> "\x1B[?1049l"
  echo newTuiControl(SHOW_CURSOR).escape() # ==> "\x1B[?25h"
  echo newTuiControl(HIDE_CURSOR).escape() # ==> "\x1B[?25l"
  echo newTuiControl(CURSOR_UP).escape() # ==> "\x1B[1A"
  echo newTuiControl(CURSOR_DOWN).escape() # ==> "\x1B[1B"
  echo newTuiControl(CURSOR_FORWARD).escape() # ==> "\x1B[1C"
  echo newTuiControl(CURSOR_BACKWARD).escape() # ==> "\x1B[1D"
  echo newTuiControl(ERASE_IN_LINE).escape() # ==> "\x1B[2K"
  echo newTuiControl(CURSOR_MOVE_TO_COLUMN).escape() # ==> "\x1B[2G"
  echo newTuiControl(CURSOR_MOVE_TO).escape() # ==> "\x1B[2;2H"
  echo newTuiControl(SET_WINDOW_TITLE, "Title").escape() # ==> "\x1B]0;Title\x07"
  echo newTuiControl(SET_WINDOW_TITLE).escape() # ==> "\x1B]0;tuicontrol_group0_examples\x07"
