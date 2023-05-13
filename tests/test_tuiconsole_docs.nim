import std/unittest

import tuicrown/[tuiconsole]


test "docgen":
  echo detectColorSystem() # ==> You want `TRUECOLOR` for support of full color pallet.

  echo newTuiConsoleDimension() # Detects the width / height of current terminal.

  var console = newTuiConsole(newTuiConsoleOptions(auto_colorize = true))

  # Color, style support
  # Emoji support 🌈
  console.print("Hello, [bold magenta]World[/]", ":rainbow:")

  # Variable `auto_colorize`
  console.print(true, false, 100, 0.001, "1e-6")
  console.print(":rainbow: [cyan bgWhite]TuiCrown :crown:[/]", """https://github.com/pysan3/tuicrown""")
    # URL supported!!
