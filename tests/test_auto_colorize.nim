import std/tempfiles
import std/colors
import std/os
import std/terminal
import std/strutils
import std/sequtils
import std/unittest

import tuicrown/[tuisegment, tuiconsole, tuistyles]
import file_test_utils

## auto_colorize = true
## colorize int, url etc based on predefined color pallet

let (cfile, path) = createTempFile("test_auto_colorize", "log")
let console = newTuiConsole(newTuiConsoleOptions(force_terminal = true, auto_colorize = true), file = cfile)
const endSeq = ansiResetCode

testConsole "Normal text":
  "[colRed]text in pure red" -> "\x1B[38;2;255;0;0mtext in pure red" & endSeq

testConsole "[bold green]hello world![/bold green]":
  "[bold green]hello world![/bold green]" -> "\x1B[5m\x1B[32mhello world!" & endSeq

testConsole " /foo":
  " /foo" -> " \x1B[0m\x1B[38;2;255;0;255m/\x1B[0m\x1B[1m\x1B[38;2;255;0;255mfoo" & endSeq

testConsole "/foo/":
  "/foo/" -> "\x1B[38;2;255;0;255m/foo/" & endSeq

testConsole "/foo/bar":
  "/foo/bar" -> "\x1B[38;2;255;0;255m/foo/\x1B[0m\x1B[1m\x1B[38;2;255;0;255mbar" & endSeq

testConsole "foo/bar/baz":
  "foo/bar/baz" -> "foo/bar/baz" & endSeq

testConsole "foo /foo/bar/baz/egg.py word":
  "foo /foo/bar/baz/egg.py word" -> "foo \x1B[0m\x1B[38;2;255;0;255m/foo/bar/baz/\x1B[0m\x1B[1m\x1B[38;2;255;0;255megg.py\x1B[0m word" & endSeq

testConsole "foo /foo/bar/ba._++z/egg+.py word":
  "foo /foo/bar/ba._++z/egg+.py word" -> "foo \x1B[0m\x1B[38;2;255;0;255m/foo/bar/ba._++z/\x1B[0m\x1B[1m\x1B[38;2;255;0;255megg+.py\x1B[0m word" & endSeq

testConsole "https://example.org?foo=bar#header":
  "https://example.org?foo=bar#header" -> "\x1B[4m\x1B[1m\x1B[38;2;0;0;255mhttps://example.org?foo=bar#header" & endSeq

testConsole "1234567.34":
  "1234567.34" -> "\x1B[5m\x1B[38;2;0;255;255m1234567.34" & endSeq

testConsole "1 / 2":
  "1 / 2" -> "\x1B[5m\x1B[38;2;0;255;255m1\x1B[0m \x1B[0m\x1B[38;2;255;0;255m/\x1B[0m \x1B[0m\x1B[5m\x1B[38;2;0;255;255m2" & endSeq

testConsole "-1 / 123123123123":
  "-1 / 123123123123" -> "\x1B[5m\x1B[38;2;0;255;255m-1\x1B[0m \x1B[0m\x1B[38;2;255;0;255m/\x1B[0m \x1B[0m\x1B[5m\x1B[38;2;0;255;255m123123123123" & endSeq

testConsole "127.0.1.1 bar 192.168.1.4 2001:0db8:85a3:0000:0000:8a2e:0370:7334 foo":
  "127.0.1.1 bar 192.168.1.4 2001:0db8:85a3:0000:0000:8a2e:0370:7334 foo" ->
      "\x1B[5m\x1B[1m\x1B[38;2;0;128;0m127.0.1.1\x1B[0m bar \x1B[0m\x1B[5m\x1B[1m\x1B[38;2;0;128;0m192.168.1.4\x1B[0m \x1B[0m\x1B[5m\x1B[1m\x1B[38;2;0;128;0m2001:0db8:85a3:0000:0000:8a2e:0370:7334\x1B[0m foo" & endSeq
