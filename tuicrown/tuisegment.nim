## This module defines TuiSegment_ which stores text with its styles.
##
## ---
##
## This module works with the inner representation of the segments.
##
## If you want to see working examples with rendered text in your terminal,
## go see examples in [tuicrown/tuiconsole module].
##
## ---
##
## A TuiSegment_ will be rendered in the following order.
## For more detailed explanation, see print_
## 1. controls
## 2. style
## 3. text
##
## Init:
## - newTuiSegment_

import std/colors
import std/tables
import std/enumerate
import std/macros
import std/sugar
import std/terminal
import std/sequtils
import std/strformat
import std/options
import fungus
import nimoji

import tuicontrol
import tuistyles
import tuivariables
import utils

type
  TuiSegment* = ref object of RootObj
    text*: string
    style*: TuiStyles
    controls*: seq[TuiControl]
    is_colorized*: bool

func newTuiSegment*(
    text: string = "",
    style: TuiStyles = newTuiStyles(),
    controls: seq[TuiControl] = newSeq[TuiControl](),
    is_colorized: bool = false,
  ): auto = TuiSegment(text: text, style: style, controls: controls, is_colorized: is_colorized)

func `==`*(self: TuiSegment, o: TuiSegment): bool =
  (self.text == o.text) and
  (self.style == o.style) and
  zip(self.controls, o.controls).allIt(it[0] == it[1])

func len*(self: TuiSegment): int = self.text.len

func copy*(refObj: TuiSegment, copyControls = false): auto =
  ## Returns a copy of `refObj`.
  ##
  ## Result contains only the text and latest `fgColor` and `bgColor`.
  ## Therefore, the override chain of colors is not copied.
  ##
  ## Ref. `tuicrown/tuistyles: copy <tuistyles.html#copy%2CTuiStyles>`_
  result = newTuiSegment(refObj.text, refObj.style.copy())
  if copyControls:
    result.controls.add(refObj.controls)

func deepCopy*(refObj: TuiSegment, copyControls = false): auto =
  ## Returns a copy of `refObj`.
  ##
  ## Result contains the text and the whole chain of `fgColor` and `bgColor`.
  ##
  ## Ref. `tuicrown/tuistyles: deepCopy <tuistyles.html#deepCopy%2CTuiStyles>`_
  result = newTuiSegment(refObj.text, refObj.style.deepCopy())
  if copyControls:
    result.controls.add(refObj.controls)

func `$`*(self: TuiSegment): auto =
  ## Mainly for debugging purpose.
  ##
  ## If you want to print the segment as is, see print_ instead.
  ##
  ## Ref. print_
  &"""("{self.text}", {self.style}, {self.controls})"""

proc colorize*(self: TuiSegment): seq[TuiSegment] =
  ## Colorize the output string based on regex pattern matching.
  ##
  ## Returns seq of TuiSegment_ each containing a substring of previous text, in order.
  ## Returned TuiSegment_ is labeled with `result.is_colorized = true`.
  ##
  ## .. importdoc:: tuiconsole.nim
  ## Used when `auto_colorize = true` option is passed to newTuiConsoleOptions_.
  ##
  ## .. importdoc:: tuivariables.nim
  ## Regex processing and in-depth implementation is written in [module tuicrown/tuivariables].
  ##
  ## Ref.
  ## - match_
  defer: result.apply((it: var TuiSegment) => (it.is_colorized = true))
  let basic = newTuiSegment(style = self.style, controls = self.controls)
  result.add(basic.copy())
  let matchSeq = reprHighlighter.match(self.text)
  var prev_id = -1
  for (t, id) in zip(self.text, matchSeq.ids):
    if id != prev_id:
      var subseg = basic.copy()
      if matchSeq.pool.low <= id and id <= matchSeq.pool.high:
        subseg.style += matchSeq.pool[id].optTuiStyles.get()
      if result[^1].text.len == 0:
        result[^1] = subseg
      else:
        result.add(subseg)
      prev_id = id
    result[^1].text &= t

proc print*(f: File, self: TuiSegment) =
  ## Prints the segment `self` to file `f`.
  ##
  ## .. importdoc:: tuistyles.nim
  ## Ref.
  ## - newTuiSegment_
  ## - newTuiStyles_
  runnableExamples:
    import std/terminal
    import tuicrown/tuistyles

    stdout.print(newTuiSegment("red text\n", newTuiStyles(fgRed)))
  for ctrl in self.controls:
    f.print(ctrl)
  f.print(self.style)
  f.write(self.text.emojize)
  f.resetAttributes()

proc print*(f: File, segseq: seq[TuiSegment]) =
  ## Prints sequence of TuiSegment_ to file `f`.
  ##
  ## Ref.
  ## - fromString_
  runnableExamples:
    stdout.print(fromString("[red]red text, [blue]blue text[/]\n"))
  for seg in segseq:
    f.print(seg)

func addStyle*(self: var TuiSegment, style: TuiStyles) = self.style += style
func addStyle*(self: var TuiSegment, arg: seq[Style]) = self.addStyle(newTuiStyles(styles = arg))
func addStyle*(
    self: var TuiSegment,
    color: TuiFGType | ForegroundColor | Color = TuiFGType TuiFGNone.init;
    bgColor: TuiBGType | BackgroundColor | Color = TuiBGType TuiBGNone.init;
    styles: seq[Style] = newSeq[Style]();
  ) = self.addStyle(newTuiStyles(color, bgColor, styles))

func delStyle*(self: var TuiSegment, style: TuiStyles) = self.style -= style
func delStyle*(self: var TuiSegment, arg: seq[Style]) = self.delStyle(newTuiStyles(styles = arg))
func delStyle*(
    self: var TuiSegment,
    color: TuiFGType | ForegroundColor | Color = TuiFGType TuiFGNone.init;
    bgColor: TuiBGType | BackgroundColor | Color = TuiBGType TuiBGNone.init;
    styles: seq[Style] = newSeq[Style]();
  ) = self.delStyle(newTuiStyles(color, bgColor, styles))

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

mainExamples:
  import tuicrown/tuistyles
  import std/[terminal, colors]

  # The following examples print out the inner representation of segments.
  #
  # If you want to see the rendered output with colors in your terminal,
  # read examples in `tuicrown/tuiconsole`.

  ## From String
  echo "fromString"
  echo fromString("[red]hoge")
  echo fromString("normal[red u]red underline[/u]only red[/red]normal")

  ## Styles
  echo "Styles"
  echo newTuiStyles()
  echo newTuiStyles(@[styleBright])
  echo newTuiStyles(fgRed)
  echo newTuiStyles(colBlue)
  echo newTuiStyles(fgRed, colBlue)

  ## Segments
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

  ## Copy and Deepcopy
  var newseg = seg.copy()
  newseg.delStyle(colRed)
  echo newseg

  var deepseg = seg.deepCopy()
  deepseg.delStyle(colRed)
  echo deepseg
