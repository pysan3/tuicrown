import std/colors
import std/tables
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
import fungus

adtEnum(TuiFGType):
  TuiFGNone
  TuiForegroundColor: ForegroundColor
  TuiFGColor: Color
adtEnum(TuiBGType):
  TuiBGNone
  TuiBackgroundColor: BackgroundColor
  TuiBGColor: Color

macro enumFuncs(head: untyped, long: untyped): untyped =
  var body = newSeq[string]()
  let
    s = $(repr(head).strip)
    l = $(repr(long).strip)
    u = s.toUpperAscii()
    t = &"Tui{u}Type"
    none = &"Tui{u}None"
  body.add(&"func {s}None*(): {t} = {t} {none}.init()")
  body.add(&"func isNone*(self: {t}): auto = self.kind == {none}Kind")
  body.add(&"func isSome*(self: {t}): auto = not self.isNone()")
  body.add(&"func get*(self: {t}, otherwise: {t} = {s}None()): {t} = return if self.isNone(): otherwise else: self")
  body.add(&"""
func equals*(self: {t}, o: {t}, bothNoneReturnsTrue = false): auto =
  (bothNoneReturnsTrue or self.isSome and self.isSome) and adtEqual(self, o)
""")
  body.add(&"func `==`*(self: {t}, o: {t}): auto = equals(self, o, true)")
  body.add(&"""
func {s}Color*(x: {t} | {l} | Color = {s}None()): {t} =
  when typeof(x) is {t}:
    result = x
  elif typeof(x) is {l}:
    result = Tui{l}.init(x)
  elif typeof(x) is Color:
    result = Tui{u}Color.init(x)
  else:
    result = {s}None()
""")
  # echo body.join("\n")
  result = parseStmt(body.join("\n"))

enumFuncs fg: ForegroundColor
enumFuncs bg: BackgroundColor

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
  TuiStyles* = ref object of RootObj
    # fgColor*: TuiFGType
    # bgColor*: TuiBGType
    fgColors*: seq[TuiFGType]
    bgColors*: seq[TuiBGType]
    styles*: seq[Style]
  TuiSegment* = ref object of RootObj
    text*: string
    style*: TuiStyles
    controls*: seq[TuiControl]

func addUniq*[T](a: var seq[T], b: T) =
  if b notin a: a.add(b)
func addUniq*[T](a: var seq[T], b: seq[T]) = a.add(b.filterIt(it notin a))
func deleteIf*[T](a: var seq[T], i: int) =
  if a.low <= i and i <= a.high:
    a.delete(i)

func fgColor*(self: TuiStyles): auto =
  if self.fgColors.len > 0: self.fgColors[^1] else: fgNone()
func `fgColor=`*(self: TuiStyles, o: TuiFGType) =
  if o.isSome():
    self.fgColors.add(o)
func `fgColor+`*(self: TuiStyles, o: seq[TuiFGType]): auto =
  self.fgColors.addUniq(o)
  return self.fgColor

func bgColor*(self: TuiStyles): auto =
  if self.bgColors.len > 0: self.bgColors[^1] else: bgNone()
func `bgColor=`*(self: TuiStyles, o: TuiBGType) =
  if o.isSome():
    self.bgColors.add(o)
func `bgColor+`*(self: TuiStyles, o: seq[TuiBGType]): auto =
  self.bgColors.addUniq(o)
  return self.bgColor

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
    color: TuiFGType | ForegroundColor | Color = TuiFGType TuiFGNone.init;
    bgColor: TuiBGType | BackgroundColor | Color = TuiBGType TuiBGNone.init;
    styles: seq[Style] = newSeq[Style]();
  ): TuiStyles =
  result = TuiStyles(fgColors: newSeq[TuiFGType](), bgColors: newSeq[TuiBGType](), styles: styles)
  result.fgColor = fgColor(color)
  result.bgColor = bgColor(bgColor)
proc newTuiStyles*(arg: seq[Style]): TuiStyles = newTuiStyles(styles = arg)

proc copy*(refObj: TuiStyles): auto =
  result = newTuiStyles(refObj.fgColor, refObj.bgColor)
  result.styles.add(refObj.styles)

proc deepCopy*(refObj: TuiStyles): auto =
  result = TuiStyles(fgColors: newSeq[TuiFGType](), bgColors: newSeq[TuiBGType](), styles: newSeq[Style]())
  result.fgColors.add(refObj.fgColors)
  result.bgColors.add(refObj.bgColors)
  result.styles.add(refObj.styles)

proc print*(self: TuiStyles): string =
  "[" & [
    "bg: " & (if self.bgColor.isSome: $self.bgColor.get() else: ""),
    "fg: " & (if self.fgColor.isSome: $self.fgColor.get() else: ""),
    "st: " & (if self.styles.len > 0: $self.styles else: ""),
  ].filterIt(it.len > 4).join(", ") & "]"

proc `$`*(self: TuiStyles): string =
  self.print

proc `+=`*(self: var TuiStyles, o: TuiStyles) =
  self.fgColor = o.fgColor
  self.bgColor = o.bgColor
  self.styles.addUniq(o.styles)
proc `-=`*(self: var TuiStyles, o: TuiStyles) =
  self.fgColors.deleteIf(self.fgColors.find(o.fgColor))
  self.bgColors.deleteIf(self.bgColors.find(o.bgColor))
  self.styles.keepItIf(it notin o.styles)
proc `==`*(self: TuiStyles, o: TuiStyles): bool =
  (self.fgColor == o.fgColor) and
  (self.bgColor == o.bgColor) and
  self.styles.allIt(it in o.styles)

proc newTuiSegment*(
    text: string = "",
    style: TuiStyles = newTuiStyles(),
    controls: seq[TuiControl] = newSeq[TuiControl](),
  ): auto = TuiSegment(text: text, style: style, controls: controls)

func `==`*(self: TuiSegment, o: TuiSegment): bool =
  (self.text == o.text) and
  (self.style == o.style) and
  zip(self.controls, o.controls).allIt(it[0] == it[1])

func len*(self: TuiSegment): int = self.text.len

proc copy*(refObj: TuiSegment, copyControls = false): auto =
  result = newTuiSegment(refObj.text, refObj.style.copy())
  if copyControls:
    result.controls.add(refObj.controls)

proc deepCopy*(refObj: TuiSegment, copyControls = false): auto =
  result = newTuiSegment(refObj.text, refObj.style.deepCopy())
  if copyControls:
    result.controls.add(refObj.controls)

func `$`*(self: TuiSegment): auto =
  &"""("{self.text}", {self.style}, {self.controls})"""

func addStyle*(self: var TuiSegment, style: TuiStyles) =
  self.style += style
func addStyle*(
    self: var TuiSegment,
    color: TuiFGType | ForegroundColor | Color = TuiFGType TuiFGNone.init;
    bgColor: TuiBGType | BackgroundColor | Color = TuiBGType TuiBGNone.init;
    styles: seq[Style] = newSeq[Style]();
  ) = self.addStyle(newTuiStyles(color, bgColor, styles))
func addStyle*(self: var TuiSegment, arg: seq[Style]) = self.addStyle(newTuiStyles(styles = arg))
func delStyle*(self: var TuiSegment, style: TuiStyles) =
  self.style -= style
func delStyle*(
    self: var TuiSegment,
    color: TuiFGType | ForegroundColor | Color = TuiFGType TuiFGNone.init;
    bgColor: TuiBGType | BackgroundColor | Color = TuiBGType TuiBGNone.init;
    styles: seq[Style] = newSeq[Style]();
  ) = self.delStyle(newTuiStyles(color, bgColor, styles))
func delStyle*(self: var TuiSegment, arg: seq[Style]) = self.delStyle(newTuiStyles(styles = arg))

proc findIf*[T](s: seq[T], pred: (x: T) -> bool): Option[T] =
  for x in s:
    if pred(x):
      return some(x)
  return none(T)

func findSubstr*(s: string, t: string, strFroms: seq[int]): bool =
  strFroms.anyIt((it == 0 and s == t) or s.substr(it) == t)

proc get*[T: enum](E: typedesc[T], idx: string, default: Option[T] = none(T), strFroms: seq[int] = newSeq[int]()): Option[T] =
  result = E.toSeq.findIf((it: T) => it.symbolName.toLowerAscii.findSubstr(idx, strFroms))
  if result.isNone() and not default.isNone():
    result = default

const styleLookUp = {
  "b": styleBlink,
  "bold": styleBlink,
  "i": styleItalic,
  "r": styleReverse,
  "s": styleStrikethrough,
  "u": styleUnderscore,
}.toTable()
proc searchStyle*(token: string): Option[Style] =
  if token in styleLookUp:
    return some(styleLookUp[token])
  return Style.get(token, strFroms = @[0, 5])

proc searchFGBG*[T: enum](E: typedesc[T], token: string): Option[T] =
  return T.get(token, strFroms = @[0, 2])

proc searchColor*(token: string): Option[Color] =
  let t = token.substr(token.startsWith("col").ord * 3)
  if t.isColor:
    return some(t.parseColor())
  return none(Color)

proc parseStr*(str: string, isBackground: bool): Option[TuiStyles] =
  if (let tmp = searchStyle(str); tmp).isSome:
    return some(newTuiStyles(styles = @[tmp.get()]))
  elif not isBackground and (let tmp = ForegroundColor.searchFGBG(str); tmp).isSome:
    return some(newTuiStyles(color = tmp.get()))
  elif (let tmp = BackgroundColor.searchFGBG(str); tmp).isSome:
    return some(newTuiStyles(bgColor = tmp.get()))
  elif (let tmp = searchColor(str); tmp).isSome:
    if isBackground:
      return some(newTuiStyles(bgColor = tmp.get()))
    else:
      return some(newTuiStyles(color = tmp.get()))
  return none(TuiStyles)

proc newTuiStyles*(old: TuiStyles, texts: string): TuiStyles =
  if texts == "/":
    return newTuiStyles()
  result = if old.isNil: newTuiStyles() else: old.deepCopy()
  for s in texts.toLowerAscii.split(' ').filterIt(it.len > 0):
    var str = s
    let reverse = s[0] == '/'
    if reverse: str = s.substr(1)
    let isBackground = s.startsWith("bg:")
    let isForeground = s.startsWith("fg:")
    if (isBackground or isForeground): str = s.substr(3)
    let style = parseStr(str, isBackground)
    if style.isSome:
      if reverse: result -= style.get()
      else: result += style.get()

proc fromString*(text: string): seq[TuiSegment] {.discardable.} =
  var
    blockstart: int = -1
    accumfrom: int = 0
  result.add(newTuiSegment())
  for i, s in enumerate(text):
    if s == '[':
      blockstart = if blockstart < 0: i + 1 else: -1
      if blockstart > 1:
        result[^1].text.add(text[accumfrom..<i])
    elif s == ']' and blockstart >= 0:
      let subs = text[blockstart..<i]
      result.add(newTuiSegment(style = newTuiStyles(result[^1].style, subs)))
      blockstart = -1
      accumfrom = i + 1
  if accumfrom < text.len:
    result[^1].text.add(text[accumfrom..<text.len])

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
  echo newTuiStyles(@[styleBright])
  echo newTuiStyles(fgRed)
  echo newTuiStyles(colBlue)
  echo newTuiStyles(fgRed, colBlue)

  echo "Segment"
  echo newTuiSegment()
  echo newTuiSegment("Segment")
  echo newTuiSegment("Segment", newTuiStyles(fgRed))
  var seg = newTuiSegment("test", newTuiStyles(bgColor = colBlue))
  echo seg
  seg.addStyle(fgRed, colRed)
  echo seg
  seg.addStyle(colRed)
  while seg.style.bgColor.isSome:
    seg.delStyle(bgColor = seg.style.bgColor)
  echo seg
  # seg.delStyle(colRed, colRed)
  # echo seg

  var newseg = seg.copy()
  newseg.delStyle(colRed)
  echo newseg
  echo seg

  var deepseg = seg.deepCopy()
  deepseg.delStyle(colRed)
  echo deepseg
  echo seg

  echo newTuiStyles(nil, "fgRed")
  echo newTuiStyles(nil, "fg:red")
  echo newTuiStyles(nil, "bg:red")
  echo newTuiStyles(nil, "fg:gray")
  echo newTuiStyles(nil, "gray")
  echo newTuiStyles(nil, "bold")
  echo newTuiStyles(nil, "underscore")

  var st = newTuiStyles(nil, "fgRed")
  echo st
  st = newTuiStyles(st, "bg:gray")
  echo st
  st = newTuiStyles(st, "bold")
  st = newTuiStyles(st, "bright")
  echo st

  echo fromString("[red]hoge")
  echo fromString("normal[red u]red underline[/u]only red[/red]normal")

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
