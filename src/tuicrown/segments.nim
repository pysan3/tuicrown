import std/colors
import std/os
import std/enumerate
import std/macros
import std/bitops
import std/terminal
import std/enumutils
import std/strutils
import std/sequtils
import std/sugar
import std/options
import std/strformat

import submodule

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
  TuiFGType* = Option[ForegroundColor] | Option[Color]
  TuiBGType* = Option[BackgroundColor] | Option[Color]
  TuiStyles* = ref object of RootObj
    # fgColor*: TuiFGType
    # bgColor*: TuiBGType
    foreground: Option[ForegroundColor]
    fgclr: Option[Color]
    background: Option[BackgroundColor]
    bgclr: Option[Color]
    styles*: seq[Style]
  TuiSegment* = ref object of RootObj
    text*: string
    styles*: TuiStyles
    controls*: seq[TuiControl]

func fgColor(self: TuiStyles): TuiFGType =
  if self.foreground.isSome():
    return self.foreground
  elif self.fgclr.isSome():
    return self.fgclr
  return none(ForegroundColor)
func `fgColor=`(self: var TuiStyles, value: Option[ForegroundColor] = none(ForegroundColor)) {.inline.} =
  self.foreground = value
func `fgColor=`(self: var TuiStyles, value: Option[Color]) {.inline.} =
  self.foreground = none(ForegroundColor)
  self.fgclr = value
func `fgColor=`(self: var TuiStyles, value: ForegroundColor | Color) {.inline.} =
  self.fgColor = some(value)
func bgColor(self: TuiStyles): TuiBGType =
  if self.background.isSome():
    return self.background
  elif self.bgclr.isSome():
    return self.bgclr
  return none(BackgroundColor)
func `bgColor=`(self: var TuiStyles, value: Option[BackgroundColor] = none(BackgroundColor)) {.inline.} =
  self.background = value
func `bgColor=`(self: var TuiStyles, value: Option[Color]) {.inline.} =
  self.background = none(BackgroundColor)
  self.bgclr = value
func `bgColor=`(self: var TuiStyles, value: BackgroundColor | Color) {.inline.} =
  self.bgColor = some(value)

func argsWithDefault[T](args: seq[T], index: int, default: T): T =
  if index >= 0 and index < args.len:
    return args[index]
  return default

proc newTuiControl*(t: ControlType, title: string): TuiControl =
  result = &"\x1b]0;{title}\x07"

proc newTuiControl*(t: ControlType, args: seq[string]): TuiControl =
  result = newTuiControl(t, args.map((x: string) => $x).join(" "))

proc newTuiControl*(t: ControlType, args: seq[int]): TuiControl =
  if t <= HIDE_CURSOR:
    result = $t
  elif t <= CURSOR_BACKWARD:
    let param = argsWithDefault(args, 0, 1)
    result = &"\x1b[{param}{t}"
  elif t <= CURSOR_MOVE_TO_COLUMN:
    let param = argsWithDefault(args, 0, 1)
    result = &"\x1b[{param + 1}{t}"
  elif t <= CURSOR_MOVE_TO:
    let
      x = argsWithDefault(args, 0, 1)
      y = argsWithDefault(args, 1, 1)
    result = &"\x1b[{y + 1};{x + 1}{t}"
  else:
    var targs = args.map((x) => $x)
    if targs.len == 0:
      targs.add(getAppFilename().substr(getAppDir().len + 1))
      when declared(commandLineParams):
        for p in commandLineParams(): targs.add(p)
    return newTuiControl(t, targs)

proc newTuiControl*(t: ControlType, args: varargs[int]): TuiControl =
  return newTuiControl(t, args.toSeq)

proc newTuiStyles*(
    color: TuiFGType = none(ForegroundColor),
    bgColor: TuiBGType = none(BackgroundColor),
    styles: seq[Style] = newSeq[Style](),
  ): TuiStyles =
  result = new TuiStyles
  result.fgColor = color
  result.bgColor = bgColor
  result.styles = styles

proc newTuiStyles*(color: ForegroundColor): TuiStyles = newTuiStyles(color = some(color))
proc newTuiStyles*(bgColor: BackgroundColor): TuiStyles = newTuiStyles(bgColor = some(bgColor))
proc newTuiStyles*(color: Color): TuiStyles = newTuiStyles(color = some(color))
# proc newTuiStyles*(styles: seq[Style]): TuiStyles = newTuiStyles(styles = styles)
# proc newTuiStyles*(styles: varargs[Style]): TuiStyles = newTuiStyles(styles = styles.toSeq)
# proc newTuiStyles*(): TuiStyles = newTuiStyles()

proc print*(self: TuiStyles): string =
  "[" & [
    "bg: " & (if self.bgColor.isSome: $self.bgColor.get() else: ""),
    "fg: " & (if self.fgColor.isSome: $self.fgColor.get() else: ""),
    "st: " & (if self.style.isSome: $self.style.get() else: ""),
  ].filterIt(it.len > 4).join(", ") & "]"

proc `$`*(self: TuiStyles): string =
  self.print

# controls: seq[TuiControl] = newSeq[TuiControl](),
# proc newTuiStyles*(controls: seq[TuiControl]): TuiStyles = newTuiStyles(controls: controls)
# proc newTuiStyles*(controls: varargs[TuiControl]): TuiStyles = newTuiStyles(controls: controls.toSeq)

when isMainModule:
  echo newTuiControl(BELL).escape()
  echo newTuiControl(CARRIAGE_RETURN).escape()
  echo newTuiControl(HOME).escape()
  echo newTuiControl(CLEAR).escape()
  echo newTuiControl(ENABLE_ALT_SCREEN).escape()
  echo newTuiControl(DISABLE_ALT_SCREEN).escape()
  echo newTuiControl(SHOW_CURSOR).escape()
  echo newTuiControl(HIDE_CURSOR).escape()
  echo newTuiControl(CURSOR_UP).escape()
  echo newTuiControl(CURSOR_DOWN).escape()
  echo newTuiControl(CURSOR_FORWARD).escape()
  echo newTuiControl(CURSOR_BACKWARD).escape()
  echo newTuiControl(ERASE_IN_LINE).escape()
  echo newTuiControl(CURSOR_MOVE_TO_COLUMN).escape()
  echo newTuiControl(CURSOR_MOVE_TO).escape()
  echo newTuiControl(SET_WINDOW_TITLE, "Title").escape()
  echo newTuiControl(SET_WINDOW_TITLE).escape()

  echo "Styles:"
  echo newTuiStyles()

## Color:
## red, green ...
## (fgRed, ...), (bgRed, ...)
## #ff0000
## (fg:red, ...)
## TuiSegment.addStyle(color=Color|ForegroundColor, bgColor=BackgroundColor)
## Style:
## [bold], [b] -> [/bold]
## TuiSegment.addStyle(style=seq[Styles])
## Control:
## [??]
## TuiSegment.addStyle(TuiControl(CURSOR_UP, @[]))
## Text:
## newTuiSegment(text: "hoge", styles: TuiStyles(...))
## newTuiSegment(text: "hoge").addStyles(TuiStyles(...))
## stringToTuiSegment("[red]hoge")
