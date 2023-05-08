import std/colors
import std/tables
import std/enumerate
import std/macros
import std/terminal
import std/sequtils
import std/strformat
import fungus

import control
import styles

type
  TuiSegment* = ref object of RootObj
    text*: string
    style*: TuiStyles
    controls*: seq[TuiControl]

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
    
proc print*(f: File, self: TuiSegment) =
  for ctrl in self.controls:
    f.print(ctrl)
  f.print(self.style)
  f.write(self.text)
  f.resetAttributes()

proc print*(f: File, segseq: seq[TuiSegment]) =
  for seg in segseq:
    f.print(seg)

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

proc fromString*(text: string): seq[TuiSegment] {.discardable.} =
  var
    blockstart: int = -1
    accumfrom: int = 0
  defer: result.keepItIf(it.len > 0)
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
