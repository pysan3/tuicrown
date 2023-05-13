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

type
  TuiConsoleBufferLocal* = ref object of RootObj
    segseq*: seq[TuiSegment]
    index*: int
  TuiConsoleDimension* = ref object of RootObj
    width*: int
    height*: int
  TuiConsoleOptions* = ref object of RootObj
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
    buffer*: TuiConsoleBufferLocal
    buffer_lock*: Lock
    file*: File
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

proc detectColorSystem(): ColorSystem =
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
    auto_colorize = false,
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
  )
  result.buffer_lock.initLock()

macro conslock*(c: TuiConsole, body: untyped): untyped =
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
  self.buffer.segseq.setLen(0)

proc control*(self: TuiConsole, controls: varargs[TuiControl]) =
  conslock self:
    self.buffer.segseq.add(newTuiSegment(controls = controls.toSeq))

proc control*(self: TuiConsole, controls: varargs[ControlType]) =
  conslock self:
    self.buffer.segseq.add(newTuiSegment(controls = controls.toSeq.mapIt(newTuiControl(it))))

proc clear*(self: TuiConsole, home = true) =
  if home:
    self.control(ControlType.CLEAR, ControlType.HOME)
  else:
    self.control(ControlType.CLEAR)

proc printWithOpt*(
  self: TuiConsole;
  sep: string = " ";
  endl: string = "\n";
  args: varargs[string, `$`];
) =
  conslock self:
    self.buffer.segseq.add(fromString(args.join(sep) & endl))

proc print*(
  self: TuiConsole;
  args: varargs[string, `$`];
) = unpackVarargs(self.printWithOpt, " ", "\n", args)

when isMainModule:
  echo detectColorSystem()
  echo newTuiConsoleDimension()
  echo newTuiConsoleOptions()
  var console = newTuiConsole(newTuiConsoleOptions())
  echo console.is_terminal()
  console.print("[bgWhite fg:red]red and white[/]", 100, "[u b]200[/b]", "[fgBlue]300", 400, "[/]reset")