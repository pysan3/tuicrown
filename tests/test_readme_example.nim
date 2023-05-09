import tuicrown/[tuiconsole]

let console = newTuiConsole(newTuiConsoleOptions()) # Console object with default options

console.print("[green]green text[/]")
console.print("[i]italic text[/]")
console.print("[i red]red and italic text[/]")
console.print("[u yellow]yellow and underlined,[/yellow] only color is removed,[i bg:blue] and now added italic with blue background")
