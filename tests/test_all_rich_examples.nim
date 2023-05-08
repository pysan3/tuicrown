## WIP

import std/colors

import unittest

import tuicrown/[segment, styles, console]

let cons = newTuiConsole(newTuiConsoleOptions())

test "^ Colors":
  cons.printWithOpt(
    sep = "\n",
    endl = "\n",
    "✓ [bold green]4-bit color[/]",
    "✓ [bold blue]8-bit color[/]",
    "✓ [bold magenta]Truecolor (16.7 million)[/]",
    "✓ [bold yellow]Dumb terminals[/]",
    "✓ [bold cyan]Automatic color conversion",
  )

test "^ Colors Contents":
  echo fromString("✓ [bold green]4-bit color[/]")
  echo fromString("✓ [bold blue]8-bit color[/]")
  echo fromString("✓ [bold magenta]Truecolor (16.7 million)[/]")
  echo fromString("✓ [bold yellow]Dumb terminals[/]")
  echo fromString("✓ [bold cyan]Automatic color conversion")

proc color(r, g, b: float32): Color =
  let
    x = (r * 255).toInt.min(255).max(0)
    y = (g * 255).toInt.min(255).max(0)
    z = (b * 255).toInt.min(255).max(0)
  return rgb(x, y, z)

proc hsl2colorsub(p, q, s: float32): float32 =
  var t = s
  if t < 0: t += 1
  if t > 1: t -= 1
  if t < 1.0/6: return p + (q - p) * 6 * t
  if t < 1.0/2: return q
  if t < 2.0/3: return p + (q - p) * (2.0/3 - t) * 6
  return p

proc hsl2color(h, s, l: float32): Color =
  ## convert ColorHSL to Color
  if s == 0.0:
    return color(l, l, l)
  var q = if l < 0.5: l * (1 + s) else: l + s - l * s
  var p = 2 * l - q
  return color(
    hsl2colorsub(p, q, h + 1.0/3),
    hsl2colorsub(p, q, h),
    hsl2colorsub(p, q, h - 1.0/3),
  )

test "^ ColorMap":
  let w = cons.dim.width
  var segseq = newSeq[TuiSegment]()
  for y in 0..<5:
    for x in 0..<w:
      let h = x.toFloat / w.toFloat
      let l = 0.1 + ((y.toFloat / 5.0) * 0.7)
      let upper = hsl2color(h, 1.0, l)
      let lower = hsl2color(h, 1.0, l + 0.07)
      segseq.add(newTuiSegment("▄", newTuiStyles(color = lower, bgColor = upper)))
  stdout.print(segseq)