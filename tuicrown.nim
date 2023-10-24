## 🌈 TuiCrown 👑
## ====================
##
## https://github.com/pysan3/tuicrown
##
## Tuicrown is a Nim library for rich text and beautiful formatting in the terminal.
##
## This library also provides top level aliases such as print_, input_ for ease of use.
##
## input_
## --------------------
##
## The following code-block is not accurate due to reStructuredText constraints.
##
## .. code-block:: Nim
## var prog = input("[[yellow]]Nim :crown:[[yellow]] or [[blue]]Python :snake:[[/]]?")
##
## print_
## --------------------
runnableExamples:
  print("[green]Hello Nim![/]")
  print(true, false, 100, 0.001, 1e-6)
  print("[yellow]Nim :crown:[yellow] or [blue]Python :snake:[/]?")

## Examples and Tests
## --------------------
##
## Example usages are listed in https://github.com/pysan3/tuicrown/tree/main/tests .
## If you have more interests on the syntax, take a look there.

import std/macros
import std/rdstdin
import tuicrown/tuiconsole
import tuicrown/tuicontrol
import tuicrown/tuisegment
import tuicrown/tuistyles

let gConsoleOut* = newTuiConsole(newTuiConsoleOptions(), file = stdout) ## Global console object used for `print`.
let gConsoleErr* = newTuiConsole(newTuiConsoleOptions(), file = stderr) ## Global console object writing to `stderr`.

proc print*(args: varargs[string, `$`]) =
  ## print to `stdout` with style parsing. Values will be space separated.
  runnableExamples:
    print("[green]Hello Nim :crown:![/]")
    print(true, false, 100, 0.001, 1e-6)
  unpackVarargs(gConsoleOut.print, args)

proc flush*(args: varargs[string, `$`]) =
  ## print to `stdout` but without a newline.
  gConsoleOut.printWithOpt(" ", "", args)
  gConsoleOut.flush()

proc input*(args: varargs[string, `$`]): string =
  ## Asks for user input from `stdin` with prompt colored with TuiCrown.
  ##
  ## .. code-block:: Nim
  ## var prog = input("[[yellow]]Nim :crown:[[yellow]] or [[blue]]Python :snake:[[/]]?")
  gConsoleOut.printWithOpt(" ", "", args)
  gConsoleOut.flush()
  result = readLineFromStdin("")

proc info*(args: varargs[string, `$`]) =
  ## print to `stdout` but prefixed with `[green]Info:[/]`.
  gConsoleOut.print("[green]Info:[/]")
  unpackVarargs(print, args)

proc warn*(args: varargs[string, `$`]) =
  ## print to `stdout` but prefixed with `[yellow]Warning:[/]`.
  gConsoleOut.print("[yellow]Warning:[/]")
  unpackVarargs(print, args)

proc rror*(args: varargs[string, `$`]) =
  ## print to `stdout` but prefixed with `[red]ERROR:[/]`.
  ##
  ## Error but to `stdout` -> `rror`
  gConsoleOut.print("[red]ERROR:[/]")
  unpackVarargs(print, args)

proc eprint*(args: varargs[string, `$`]) =
  ## print to `stderr` with style parsing. Values will be space separated.
  unpackVarargs(gConsoleErr.print, args)

proc einfo*(args: varargs[string, `$`]) =
  ## print to `stderr` but prefixed with `[green]Info:[/]`.
  gConsoleErr.print("[green]Info:[/]")
  unpackVarargs(eprint, args)

proc ewarn*(args: varargs[string, `$`]) =
  ## print to `stderr` but prefixed with `[yellow]Warning:[/]`.
  gConsoleErr.print("[yellow]Warning:[/]")
  unpackVarargs(eprint, args)

proc error*(args: varargs[string, `$`]) =
  ## print to `stderr` but prefixed with `[red]ERROR:[/]`.
  gConsoleErr.print("[red]ERROR:[/]")
  unpackVarargs(eprint, args)

when isMainModule:
  print "[yellow]TuiCrown :crown:[/]\n=============="
  while true:
    print input("Test any [green u]prompt[/] or [i blue]style[/]: ")
