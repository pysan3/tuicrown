## This module wraps `std/terminal.ForegroundColor / BackgroundColor`, `std/colors.Colors`
##
## A pretty hacky solution is used so be careful.
##
## This module parses styles inside brackets passed like `[green bold]`.
## The parsing mechanism is implemented in newTuiStyles_ and parseStr_.
##
## Color and style parsing is done in this order.
## If none of the the styles are found, returns `none(TuiStyles)`.
##
## - searchStyle_
## - foreground: searchFGBG_
## - background: searchFGBG_
## - searchColor_

import std/colors
import std/tables
import std/enumutils
import std/macros
import std/terminal
import std/strutils
import std/sequtils
import std/sugar
import std/options
import std/strformat
import fungus

import utils

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
  TuiStyles* = ref object of RootObj
    # fgColor*: TuiFGType
    # bgColor*: TuiBGType
    fgColors*: seq[TuiFGType]
    bgColors*: seq[TuiBGType]
    styles*: seq[Style]

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

proc print*(f: File, self: TuiStyles) =
  var isBright = self.styles.anyIt(it == styleBright)
  f.write(self.styles.mapIt(ansiStyleCode(it)).join(""))
  match self.bgColor:
  of TuiBackgroundColor as bg_0:
    f.setBackgroundColor(bg_0, isBright)
  of TuiBGColor as bg_1:
    f.setBackgroundColor(bg_1)
  else: discard
  match self.fgColor:
  of TuiForegroundColor as fg_0:
    f.setForegroundColor(fg_0, isBright)
  of TuiFGColor as fg_1:
    f.setForegroundColor(fg_1)
  else: discard

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
  ## Returns the copy of `refObj`.
  ##
  ## Result contains only the latest `fgColor` and `bgColor`.
  ## Therefore, the override chain of colors is not copied.
  ##
  ## Also see. deepCopy_ (copies the override chain as well)
  runnableExamples:
    import std/terminal
    var st = newTuiStyles(nil, "fgRed")
    st = newTuiStyles(st, "fgBlue")
    var new_st = st.copy() # color chain is not copied. Only remembers top color: fgBlue
    new_st -= newTuiStyles(nil, "fgBlue")
    assert new_st == newTuiStyles() # nothing is left
  result = newTuiStyles(refObj.fgColor, refObj.bgColor)
  result.styles.add(refObj.styles)

proc deepCopy*(refObj: TuiStyles): auto =
  ## Returns the copy of `refObj`.
  ##
  ## Result contains all chain of colors for `fgColor` and `bgColor`.
  ##
  ## Also see. copy_ (only copies the current applied color)
  runnableExamples:
    import std/terminal
    var st = newTuiStyles(nil, "fgRed")
    st = newTuiStyles(st, "fgBlue")
    var new_st = st.deepCopy() # color chain copied
    new_st -= newTuiStyles(nil, "fgBlue")
    assert new_st == newTuiStyles(nil, "fgRed") # fgRed remains
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
  ## Returns `some(Style)` if `token` is parsed as a style.
  ##
  ## Style should be one of `std/terminal/Style` enum (matches lowercase).
  ##
  ## User can omit `style` and use just `bright` instead.
  ##
  ## Some aliases are also pre-defined.
  ## - "b": `styleBlink`
  ## - "bold": `styleBlink`
  ## - "i": `styleItalic`
  ## - "r": `styleReverse`
  ## - "s": `styleStrikethrough`
  ## - "u": `styleUnderscore`
  ##
  ## Ref. https://nim-lang.org/docs/terminal.html#Style
  if token in styleLookUp:
    return some(styleLookUp[token])
  return Style.get(token, strFroms = @[0, 5])

proc searchFGBG*[T: enum](E: typedesc[T], token: string): Option[T] =
  ## Returns `some(ForegroundColor)` or `some(BackgroundColor)` if `token` is parsed as a terminal color.
  ##
  ## Style should be one of `std/terminal/[ForegroundColor, BackgroundColor]` enum (matches lowercase).
  ##
  ## User can omit `fg` / `bg` and use just `red` instead.
  ##
  ## Ref.
  ##   - https://nim-lang.org/docs/terminal.html#BackgroundColor
  ##   - https://nim-lang.org/docs/terminal.html#ForegroundColor
  return T.get(token, strFroms = @[0, 2])

proc searchColor*(token: string): Option[Color] =
  ## Returns `some(Color)` if `token` is parsed as a color.
  ##
  ## Style is checked with `isColor` from https://nim-lang.org/docs/colors.html#isColor%2Cstring
  ##
  ## Available colors are listed here: https://nim-lang.org/docs/colors.html#10
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

runnableExamples:
  import std/[terminal, colors]
  let redfg = fgColor(fgRed) # Create fgColor object from `std/terminal/ForegroundColor`
  let bluefg = fgColor(fgBlue)
  let redbg = bgColor(bgRed)
  assert newTuiStyles(nil, "red").fgColor == redfg

  # Styles can be added inplace with `+=`. (`+` is not defined)
  var st1 = newTuiStyles(nil, "fgRed")
  st1 += newTuiStyles(nil, "bgRed")
  assert st1.fgColor == redfg and st1.bgColor == redbg
  # Inherit other styles. Colors will be overwritten.
  var st2 = newTuiStyles(st1, "fgBlue")
  assert st2.fgColor == bluefg # fgRed is overwritten by fgBlue
  assert st2.bgColor == redbg
  # `-=` subtracts styles
  st2 -= newTuiStyles(nil, "fgBlue")
  assert st2.fgColor == redfg # fgRed is brought back again

  # More ways to define colors
  assert newTuiStyles(nil, "fgRed").fgColor == redfg
  assert newTuiStyles(nil, "#FF0000").fgColor != redfg # fgRed != colorRed
  assert newTuiStyles(nil, "fg:red").fgColor == redfg # `fg:`, `bg:` can be used to hardcode fore or back
  assert newTuiStyles(nil, "bg:red").fgColor != redfg and newTuiStyles(nil, "bg:red").bgColor == redbg
  assert newTuiStyles(nil, "bgRed").bgColor == redbg

  # Styles
  # See more info at `searchStyle`
  assert newTuiStyles(nil, "b") == newTuiStyles(nil, "bold")
