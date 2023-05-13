## WIP

import std/colors

import unittest

import tuicrown/[tuisegment, tuistyles, tuiconsole]

let console = newTuiConsole(newTuiConsoleOptions())

test "^ Colors\n":
  console.printWithOpt(
    sep = "\n",
    endl = "\n",
    "✓ [i green]4-bit color[/]",
    "✓ [i blue]8-bit color[/]",
    "✓ [i magenta]Truecolor (16.7 million)[/]",
    "✓ [i yellow]Dumb terminals[/]",
    "✓ [i cyan]Automatic color conversion",
  )

test "^ Emoji and Asian Language Support\n":
  console.print(":cn: 该库支持中文，日文和韩文文本！")
  console.print(":jp: ライブラリは中国語、日本語、韓国語のテキストをサポートしています")
  console.print(":kr: 이 라이브러리는 중국어, 일본어 및 한국어 텍스트를 지원합니다")

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

test "^ ColorMap\n":
  let w = console.dim.width
  var segseq = newSeq[TuiSegment]()
  for y in 0..<5:
    for x in 0..<w:
      let h = x.toFloat / w.toFloat
      let l = 0.1 + ((y.toFloat / 5.0) * 0.7)
      let upper = hsl2color(h, 1.0, l)
      let lower = hsl2color(h, 1.0, l + 0.07)
      segseq.add(newTuiSegment("▄", newTuiStyles(color = lower, bgColor = upper)))
    segseq.add(newTuiSegment("\n"))
  stdout.print(segseq)

let color_console = newTuiConsole(newTuiConsoleOptions(force_terminal = true, auto_colorize = true))

test "^ Console with Automatic Colored Variables\n":
  color_console.print("- integer (cyan)  = 100")
  color_console.print("- string  (green) = \"TuiCrown is Awesome!!\"")
  color_console.print("- boolean (green / red: italic) = true / false")
  color_console.print("- URL     (blue)  = https://github.com/pysan3/tuicrown")
