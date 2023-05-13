## This module defines TuiConsole_ which manages all interactions with the terminal.
##
## TuiConsole_ has print_ proc which prints the strings passed as arguments but colorize them
## based on the styles defined in `[style]...[/style]` syntax.
##
## Init:
## - newTuiConsole_
##
## Options:
## - newTuiConsoleOptions_

import std/os
import std/locks
import std/strutils
import std/sequtils
import std/terminal
import std/tables
import std/strformat
import std/macros
import std/sugar

import tuisegment
import tuistyles
import tuicontrol
import utils

type
  TuiConsoleBufferLocal* = ref object of RootObj
    segseq*: seq[TuiSegment]
    index*: int
  TuiConsoleDimension* = ref object of RootObj
    width*: int
    height*: int
  TuiConsoleOptions* = ref object of RootObj
    ## Init: newTuiConsoleOptions_
    auto_colorize*: bool
    tab_size*: int
    record*: bool
    markup*: bool
    emoji*: bool
    highlight*: bool
    soft_wrap*: bool
    force_terminal*: bool
    is_interactive*: bool
  TuiConsole* = ref object of RootObj
    ## Init: newTuiConsole_
    buffer*: TuiConsoleBufferLocal
    buffer_lock*: Lock
    file*: File
    force_flush*: bool
    color_system*: ColorSystem
    o*: TuiConsoleOptions
    dim*: TuiConsoleDimension
  ColorSystem* = enum
    STANDARD, EIGHT_BIT, TRUECOLOR
  TuiOptions* = ref object of TuiConsoleOptions
    sep*: string
    endl*: string

let
  IS_MS_WINDOWS = false
  term_colors = {
    "kitty": ColorSystem.EIGHT_BIT,
    "256color": ColorSystem.EIGHT_BIT,
    "16color": ColorSystem.STANDARD
  }.toTable()

proc newTuiConsoleBufferLocal*(): TuiConsoleBufferLocal =
  TuiConsoleBufferLocal(segseq: newSeq[TuiSegment](), index: 0)

proc detectColorSystem*(): ColorSystem =
  when defined(window):
    return if windowsHasTrueColor(): ColorSystem.TRUECOLOR else: ColorSystem.EIGHT_BIT
  elif defined(linux):
    if ["truecolor", "24bit"].contains(getEnv("COLORTERM", "").toLowerAscii()):
      return ColorSystem.TRUECOLOR
    return term_colors.getOrDefault(getEnv("TERM", "").toLowerAscii().rsplit('-', maxsplit = 1)[^1],
                                    ColorSystem.STANDARD)

proc isDigit*(s: string): bool =
  s.allIt(it.isDigit)

proc newTuiConsoleDimension*(width: int = -1, height: int = -1): TuiConsoleDimension =
  TuiConsoleDimension(
    width: if width > 0: width else: terminalWidth(),
    height: if height > 0: height else: terminalHeight(),
  )

proc `$`*(self: TuiConsoleDimension): string =
  &"""TuiConsoleDimension(width: {self.width}, height: {self.height})"""

proc newTuiConsoleOptions*(
    auto_colorize = true,
    tab_size = 2,
    record = false,
    markup = false,
    emoji = true,
    highlight = true,
    soft_wrap = false,
    force_terminal = false,
    is_interactive = false,
  ): TuiConsoleOptions =
  TuiConsoleOptions(
    auto_colorize: auto_colorize,
    tab_size: tab_size,
    record: record,
    markup: markup,
    emoji: emoji,
    highlight: highlight,
    soft_wrap: soft_wrap,
    force_terminal: force_terminal,
    is_interactive: is_interactive,
  )

proc `$`*(self: TuiConsoleOptions): string =
  &"""TuiConsoleOptions:
  auto_colorize: {self.auto_colorize}
  tab_size: {self.tab_size}
  record: {self.record}
  markup: {self.markup}
  emoji: {self.emoji}
  highlight: {self.highlight}
  soft_wrap: {self.soft_wrap}
  force_terminal: {self.force_terminal}
  is_interactive: {self.is_interactive}
"""

proc newTuiConsole*(o: TuiConsoleOptions,
                 color_system: string = "auto",
                 file: File = nil,
                 width: int = -1,
                 height: int = -1): TuiConsole =
  result = TuiConsole(
    buffer: newTuiConsoleBufferLocal(),
    file: if file.isNil: stdout else: file,
    color_system:
    if color_system == "auto":
        detectColorSystem()
      else: term_colors.getOrDefault(color_system,
        ColorSystem.STANDARD),
    o: o,
    dim: newTuiConsoleDimension(width, height),
    force_flush: false,
  )
  result.buffer_lock.initLock()

macro conslock*(c: TuiConsole, body: untyped): untyped =
  ## conslock (Console Lock)
  ##
  ## All operations to `file` does not want to be random across threads.
  ##
  ## To prevent that, TuiConsole object buffers the outputs to `self.buffer` and
  ## when nothing is trying to write something, it flushes the content of buffer to file (stdout).
  ##
  ## Ref.
  ## - check_buffer_
  ## - TuiConsole_
  quote do:
    `c`.buffer.index += 1
    `body`
    `c`.buffer.index -= 1
    `c`.check_buffer()

proc is_terminal*(self: TuiConsole): bool =
  defer:
    if result == true and getEnv("COLORTERM").toLowerAscii() notin ["truecolor", "24bit"]:
      putEnv("COLORTERM", "truecolor")
  if self.o.force_terminal:
    return true
  if existsEnv("FORCE_COLOR"):
    self.o.force_terminal = true
    return true
  return self.file.isatty()

proc is_dumb_terminal*(self: TuiConsole): bool =
  self.is_terminal and ["dumb", "unknown"].contains(getEnv("TERM").toLowerAscii)

proc check_buffer*(self: TuiConsole) =
  ## The actual implementation of writing to the file.
  ##
  ## This proc locks any write to `self.buffer` and flushes its content to file.
  defer: self.buffer_lock.release()
  self.buffer_lock.acquire()
  if self.buffer.index > 0:
    return
  if self.is_terminal:
    enableTrueColors()
  for seg in self.buffer.segseq:
    if self.o.auto_colorize and self.is_terminal and not seg.is_colorized:
      seg.colorize.apply((it: TuiSegment) => self.file.print(it))
    else:
      self.file.print(seg)
  if self.force_flush:
    self.file.flushFile()
    self.force_flush = false
  self.buffer.segseq.setLen(0)

proc control*(self: TuiConsole, controls: varargs[TuiControl]) =
  ## .. importdoc:: tuicontrol.nim
  ## Write sequence of TuiControl_
  conslock self:
    self.buffer.segseq.add(newTuiSegment(controls = controls.toSeq))

proc control*(self: TuiConsole, controls: varargs[ControlType]) =
  ## .. importdoc:: tuicontrol.nim
  ## Write sequence of TuiControl_
  conslock self:
    self.buffer.segseq.add(newTuiSegment(controls = controls.toSeq.mapIt(newTuiControl(it))))

proc clear*(self: TuiConsole, home = true) =
  ## Clear whole content of terminal.
  ## Same as `CTRL-L` or `clear` command in unix shells.
  ##
  ## If `home == true`: deletes everything up to the top of the terminal, making the whole screen blank.
  ## Else:              deletes the current line and puts cursor at the beginning of the line.
  if home:
    self.control(ControlType.CLEAR, ControlType.HOME)
  else:
    self.control(ControlType.CLEAR)

proc printWithOpt*(
  self: TuiConsole;
  sep: string = " ";
  endl: string = "\n";
  args: seq[string];
) =
  conslock self:
    self.buffer.segseq.add(fromString(args.join(sep) & endl))

proc printWithOpt*(
  self: TuiConsole;
  sep: string = " ";
  endl: string = "\n";
  args: varargs[string, `$`];
) = self.printWithOpt(sep, endl, args.mapIt($it).toSeq)

proc print*(
  self: TuiConsole;
  args: seq[string];
) = unpackVarargs(self.printWithOpt, " ", "\n", args)

proc print*(
  self: TuiConsole;
  args: varargs[string, `$`];
) = self.print(args.mapIt($it).toSeq)

proc flush*(self: TuiConsole) =
  conslock self:
    self.force_flush = true

mainExamples:
  echo detectColorSystem() # ==> You want `TRUECOLOR` for support of full color pallet.

  echo newTuiConsoleDimension() # Detects the width / height of current terminal.

  var console = newTuiConsole(newTuiConsoleOptions(auto_colorize = true))

  # Color, style support
  # Emoji support 🌈
  console.print("Hello, [bold magenta]World[/]", ":rainbow:")

  # Variable `auto_colorize`
  console.print(true, false, 100, 0.001, "1e-6")
  console.print(":rainbow: [cyan bgWhite]TuiCrown :crown:[/]", """https://github.com/pysan3/tuicrown""")
  #                                                               ^ -- URL parser supported!!
