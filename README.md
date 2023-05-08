# 🌈 TuiCrown 👑

[![CI status](https://github.com/alaviss/union/workflows/CI/badge.svg)](https://github.com/pysan3/tuicrown/actions?query=workflow%3ACI)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.9.3%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/pysan3/tuicrown?style=flat)](#license)

- [API documentation](https://pysan3.github.io/tuicrown/)

Tuicrown is a Nim library for rich text and beautiful formatting in the terminal.

> Generated with [`./tests/test_all_rich_examples.nim`](./tests/test_all_rich_examples.nim).

![image](https://user-images.githubusercontent.com/41065736/236928476-20cc05c4-906f-4341-8455-3c690210fd82.png)

This is possible with a very easy syntax as follows.

- `[style]`: Styles are defined inside `[` and `]`.
- `[/style]`: `/` means to revert (undo) the style.
- `[/]`: Reverts all style modification.

Such that...

```nim
let console = newTuiConsole(newTuiConsoleOptions()) # Console object with default options

console.print("[green]green text[/]")
console.print("[i]italic text[/]")
console.print("[i red]red and italic text[/]")
console.print("[u yellow]yellow and underlined,[/yellow] only color is removed,[i bg:blue] and now added italic with blue background")
```

![image](https://user-images.githubusercontent.com/41065736/236800422-1fbe16bb-2cfd-408f-bbf4-bf2db48ddfbf.png)

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
import tuicrown/tuiconsole

let console = newTuiConsole(newTuiConsoleOptions()) # Console object with default options

console.print("[i green]italic green text[/]")
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
