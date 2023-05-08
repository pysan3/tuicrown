import tuicrown/[tuiconsole]

let cons = newTuiConsole(newTuiConsoleOptions()) # Console object with default options

cons.print("[green]green text[/]")
cons.print("[i]italic text[/]")
cons.print("[i red]red and italic text[/]")
cons.print("[u yellow]yellow and underlined,[/yellow] only color is removed,[i bg:blue] and now added italic with blue background")
