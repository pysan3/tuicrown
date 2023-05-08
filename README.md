# TuiCrown

Tuicrown is a Nim library for rich text and beautiful formatting in the terminal.

![image](https://user-images.githubusercontent.com/41065736/236798038-f6e0e096-e113-415b-9f56-bb88c5da0de8.png)

This is possible with a very easy syntax as follows.

- `[style]`: Styles are defined inside `[` and `]`.
- `[/style]`: `/` means to revert (undo) the style.
- `[/]`: Reverts all style modification.

Such that...

```nim
let cons = newTuiConsole(newTuiConsoleOptions()) # Console object with default options

cons.print("[green]green text[/]")
cons.print("[i]italic text[/]")
cons.print("[i red]red and italic text[/]")
cons.print("[u yellow]yellow and underlined,[/yellow] only color is removed,[i bg:blue] and now added italic with blue background")
```

## Installation

❗ This is still in alpha stage.

- API may change without notice.

```bash
nimble install https://github.com/pysan3/tuicrown
```

- I will release this as a nimble package after `v1.0.0+`.
- Coming soon!!

## Usage

```nim
import tuicrown/console

let cons = newTuiConsole(newTuiConsoleOptions()) # Console object with default options

cons.print("[i green]italic green text[/]")
```

## Syntax

[`Tuicrown`](https://github.com/pysan3/tuicrown)'s syntax is inspired by the [Rich](https://github.com/Textualize/rich) python library.

### Color

TODO: doc

- Color
- ForegroundColor
- BackgroundColor

### Style

TODO: doc

## TODOs

- [ ] Documentation
- [ ] Tests
- [ ] Windows support
