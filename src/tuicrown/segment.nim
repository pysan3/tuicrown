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
    CURSOR_UP = "\x1b[1A"
    CURSOR_DOWN = "\x1b[1B"
    CURSOR_FORWARD = "\x1b[1C"
    CURSOR_BACKWARD = "\x1b[1D"
  ControlCode* = ControlType
  SegStyles* = (Option[BackgroundColor], Option[ForegroundColor], Option[Style])
  Segment* = ref object of RootObj
    text*: string
    styles*: SegStyles
    resetStyle*: bool
    controls*: seq[ControlCode]

func bgColor*(self: SegStyles): Option[BackgroundColor] = self[0]
func fgColor*(self: SegStyles): Option[ForegroundColor] = self[1]
func style*(self: SegStyles): Option[Style] = self[2]
func allNone*(self: SegStyles): bool =
  self[0].isNone and self[1].isNone and self[2].isNone
func `$`*(self: SegStyles): string =
  "[" & [
    "bg: " & (if self.bgColor.isSome: $self.bgColor.get() else: ""),
    "fg: " & (if self.fgColor.isSome: $self.fgColor.get() else: ""),
    "st: " & (if self.style.isSome: $self.style.get() else: ""),
  ].filterIt(it.len > 5).join(", ") & "]"

func bgcolor*(self: Segment): Option[BackgroundColor] = self.styles.bgcolor
func fgcolor*(self: Segment): Option[ForegroundColor] = self.styles.fgcolor
func style*(self: Segment): Option[Style] = self.styles.style

func newSegStyles*(
    bg: Option[BackgroundColor] = none(BackgroundColor),
    fg: Option[ForegroundColor] = none(ForegroundColor),
    styl: Option[Style] = none(Style),
  ): SegStyles = (bg, fg, styl)

func len*(self: Segment): int = self.text.len

func newSegment*(text: string = "", styles: SegStyles = newSegStyles(),
                 controls: seq[ControlCode] = @[]): Segment =
  Segment(text: text, styles: styles, resetStyle: false, controls: controls)

func newReset*(): Segment =
  result = newSegment()
  result.resetStyle = true

func rawSegment*(text: string): Segment = newSegment(text)

func line*(): Segment = rawSegment("\n")

func findIf*[T](s: seq[T], pred: (x: T) -> bool): Option[T] =
  for x in s:
    if pred(x):
      return some(x)
  return none(T)

func get*[T: enum](E: typedesc[T], idx: string, default: Option[T]): Option[T] =
  result = E.toSeq.findIf((it: T) => it.symbolName == idx)
  if result.isNone():
    result = default

func getStyles*(text: string): Option[SegStyles] =
  var res = newSegStyles()
  for s in text.split(' '):
    if s.len() > 0:
      res[0] = BackgroundColor.get(s, res[0])
      res[1] = ForegroundColor.get(s, res[1])
      res[2] = Style.get(s, res[2])
  return if res.allNone: none(SegStyles) else: some(res)

func fromString*(text: string, segseq: var seq[Segment]): seq[Segment] =
  var
    blockstart: int = -1
    accumfrom: int = 0
  for i, s in enumerate(text):
    if segseq.len == 0 or segseq[^1].len > 0:
      segseq.add(newSegment())
    if s == '[':
      blockstart = if blockstart < 0: i + 1 else: -1
      if blockstart > 1:
        segseq[^1].text.add(text[accumfrom..<i])
    elif s == ']' and blockstart >= 0:
      let
        subs = text[blockstart..<i]
        t = getStyles(subs)
      if subs == "/":
        segseq.add(newReset())
      elif t.isSome():
        segseq[^1].styles = t.get()
      else:
        segseq[^1].text.add(&"[{subs}]")
      blockstart = -1
      accumfrom = i + 1
  segseq.add(newSegment())
  if accumfrom < text.len:
    segseq[^1].text.add(text[accumfrom..<text.len])
  segseq.add(newReset())
  return segseq.filterIt(it.len > 0 or it.resetStyle)

func `$`*(self: Segment): string =
  if self.resetStyle:
    "(resetStyle)"
  else:
    &"""("{self.text}": {self.styles}, {self.controls})"""

func use*(it, cond: int): bool = bitand(1 shl it, cond) > 0

macro optionalTuple(head: typed): untyped =
  var body = newSeq[string]()
  body.add(&"proc {repr(head).strip}*(f: File, self: Segment, nocontrols = false) =")
  body.add("""  let text = (if nocontrols: "" else: self.controls.mapIt($it).join("")) & self.text""")
  body.add("  if false: discard")
  for cond in 0..<1 shl 3:
    body.add("  elif " & (0..<3).mapIt(&"self.styles[{it}]." & (if use(it, cond): "isSome" else: "isNone")).join(
        " and ") & ":")
    body.add("    styledWrite(f, " & (-1..<3).mapIt(if use(it, cond): &"self.styles[{it}].get(), " else: "").filterIt(
        it.len > 0).join("") & &"text)")
  body.add("  else: discard")
  # echo body.join("\n")
  result = parseStmt(body.join("\n"))

optionalTuple styledWrite

when isMainModule:
  var segseq = fromString("pre[fgRed]hoge[/]fuga")
  echo segseq
  for seg in segseq:
    stdout.styledWrite(seg)
