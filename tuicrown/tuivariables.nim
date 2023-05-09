import std/tables
import std/intsets
import std/options
import std/colors
import std/terminal
import std/sequtils
import std/strutils
import std/sugar
import regex

import utils
import tuistyles

let style_lookup = {
  "repr.ellipsis": newTuiStyles(color = parseColor("yellow")),
  "repr.indent": newTuiStyles(color = parseColor("green"), styles = @[styleDim]),
  "repr.error": newTuiStyles(color = parseColor("red"), styles = @[styleBlink]),
  "repr.str": newTuiStyles(color = parseColor("green")),
  "repr.brace": newTuiStyles(styles = @[styleBlink]),
  "repr.comma": newTuiStyles(styles = @[styleBlink]),
  "repr.ipv4": newTuiStyles(styles = @[styleBlink, styleBright], color = parseColor("green")),
  "repr.ipv6": newTuiStyles(styles = @[styleBlink, styleBright], color = parseColor("green")),
  "repr.eui48": newTuiStyles(styles = @[styleBlink, styleBright], color = parseColor("green")),
  "repr.eui64": newTuiStyles(styles = @[styleBlink, styleBright], color = parseColor("green")),
  "repr.tag_start": newTuiStyles(styles = @[styleBlink]),
  "repr.tag_name": newTuiStyles(color = parseColor("magenta"), styles = @[styleBlink, styleBright]),
  "repr.tag_contents": newTuiStyles(),
  "repr.tag_end": newTuiStyles(styles = @[styleBlink]),
  "repr.attrib_name": newTuiStyles(color = parseColor("yellow")),
  "repr.attrib_equal": newTuiStyles(styles = @[styleBlink]),
  "repr.attrib_value": newTuiStyles(color = parseColor("magenta")),
  "repr.number": newTuiStyles(color = parseColor("cyan"), styles = @[styleBlink]),
  "repr.number_complex": newTuiStyles(color = parseColor("cyan"), styles = @[styleBlink]),
  "repr.bool_true": newTuiStyles(color = parseColor("green"), styles = @[styleItalic, styleBright]),
  "repr.bool_false": newTuiStyles(color = parseColor("red"), styles = @[styleItalic, styleBright]),
  "repr.none": newTuiStyles(color = parseColor("magenta"), styles = @[styleItalic]),
  "repr.url": newTuiStyles(styles = @[styleUnderscore, styleBright], color = parseColor("blue")),
  "repr.uuid": newTuiStyles(color = parseColor("yellow"), styles = @[styleBright]),
  "repr.call": newTuiStyles(color = parseColor("magenta"), styles = @[styleBlink]),
  "repr.path": newTuiStyles(color = parseColor("magenta")),
  "repr.filename": newTuiStyles(color = parseColor("magenta"), styles = @[styleBright]),
}.toTable()

type
  TuiHighlighter* = ref object of RootObj
    prefix*: string
    highlights*: seq[Regex]
    lookup*: TableRef[string, TuiStyles]
  MatchResult* = (string, Option[TuiStyles], string)
  MatchSeq* = object
    ids*: seq[int]
    pool*: seq[MatchResult]

func text*(self: MatchResult): auto = self[0]
func optTuiStyles*(self: MatchResult): auto = self[1]
func hlKey*(self: MatchResult): auto = self[2]

func lookup*(self: MatchSeq, idx: int): MatchResult =
  var id = self.ids[idx]
  if self.pool.low <= id and id <= self.pool.high:
    return self.pool[id]
func `[]`*(self: MatchSeq, idx: int): MatchResult =
  self.lookup(idx)
func assign*(self: var MatchSeq, idx: int, id: int) =
  assert self.pool.low <= id and id <= self.pool.high
  self.ids[idx] = id
func len*(self: MatchSeq): auto =
  self.ids.len

proc newTuiHighlighter*(prefix = "", highlights = newSeq[seq[string]]()): TuiHighlighter =
  result = TuiHighlighter(prefix: prefix, highlights: newSeq[Regex](), lookup: style_lookup.pairs().toSeq.newTable())
  for hl in highlights:
    result.highlights.add(hl.join("|").re)

func updateLookup*(self: TuiHighlighter, k: string, v: TuiStyles) =
  self.lookup[k] = v

func updateLookup*(self: TuiHighlighter, t: TableRef[string, TuiStyles]) =
  for (k, v) in t.pairs():
    self.updateLookup(k, v)

proc match*(self: TuiHighlighter, text: string): MatchSeq {.discardable.} =
  result = MatchSeq(ids: newSeq[int](text.len).mapIt(-1), pool: newSeq[MatchResult]())
  for reg in self.highlights:
    for m in text.findAll(reg):
      for name in m.namedGroups.keys:
        var lookup = self.prefix & name
        if not self.lookup.hasKey(lookup):
          continue
        for bounds in m.group(name):
          if bounds.a > bounds.b: continue
          var subtext = text[bounds]
          result.pool.add((subtext, some(self.lookup[lookup]), lookup))
          var idx = result.pool.high
          for it in bounds:
            if result.lookup(it).optTuiStyles.isNone or result.lookup(it).text.len < subtext.len:
              result.assign(it, idx)

let
  reprHighlighter* = newTuiHighlighter("repr.", @[
    @[r"(?P<tag_start><)(?P<tag_name>[-\w.:|]*)(?P<tag_contents>[\w\W]*)(?P<tag_end>>)"],
    @[r"(?P<attrib_name>[\w_]{1,50})=(?P<attrib_value>""?[\w_]+""?)?"],
    @[r"(?P<brace>[][{}()])"],
    @[
      r"(?P<ipv4>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})",
      r"(?P<ipv6>([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})",
      r"(?P<eui64>(?:[0-9A-Fa-f]{1,2}-){7}[0-9A-Fa-f]{1,2}|(?:[0-9A-Fa-f]{1,2}:){7}[0-9A-Fa-f]{1,2}|(?:[0-9A-Fa-f]{4}\.){3}[0-9A-Fa-f]{4})",
      r"(?P<eui48>(?:[0-9A-Fa-f]{1,2}-){5}[0-9A-Fa-f]{1,2}|(?:[0-9A-Fa-f]{1,2}:){5}[0-9A-Fa-f]{1,2}|(?:[0-9A-Fa-f]{4}\.){2}[0-9A-Fa-f]{4})",
      r"(?P<uuid>[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})",
      r"(?P<call>[\w.]*?)\(",
      r"\b(?P<bool_true>true)\b|\b(?P<bool_false>false)\b|\b(?P<none>nil)\b",
      r"(?P<ellipsis>\.\.\.)",
      r"(?P<number_complex>(?<!\w)(?:\-?[0-9]+\.?[0-9]*(?:e[-+]?\d+?)?)(?:[-+](?:[0-9]+\.?[0-9]*(?:e[-+]?\d+)?))?j)",
      r"(?P<number>(?<!\w)\-?[0-9]+\.?[0-9]*(e[-+]?\d+?)?\b|0x[0-9a-fA-F]*)",
      r"(?P<path>\B(/[-\w._+]+)*\/)(?P<filename>[-\w._+]*)?",
      r"(?<![\\\w])(?P<str>b?"".*?(?<!\\)"")",
      r"(?P<url>(file|https|http|ws|wss)://[-0-9a-zA-Z$_+!`(),.?/;:&=%#]*)",
    ]
  ])

when isMainModule:
  echo reprHighlighter.match("[bold green]hello world![/bold green]")
  echo reprHighlighter.match(""""[bold green]hello world![/bold green]"""")

  echo reprHighlighter.match(" /foo")
  echo reprHighlighter.match("/foo/")
  echo reprHighlighter.match("/foo/bar")
  echo reprHighlighter.match("foo/bar/baz")

  echo reprHighlighter.match("/foo/bar/baz?foo=bar+egg&egg=baz")
  echo reprHighlighter.match("/foo/bar/baz/")
  echo reprHighlighter.match("/foo/bar/baz/egg")
  echo reprHighlighter.match("/foo/bar/baz/egg.py")
  echo reprHighlighter.match("/foo/bar/baz/egg.py word")
  echo reprHighlighter.match(" /foo/bar/baz/egg.py word")
  echo reprHighlighter.match("foo /foo/bar/baz/egg.py word")
  echo reprHighlighter.match("foo /foo/bar/ba._++z/egg+.py word")
  echo reprHighlighter.match("https://example.org?foo=bar#header")

  echo reprHighlighter.match("1234567.34")
  echo reprHighlighter.match("1 / 2")
  echo reprHighlighter.match("-1 / 123123123123")

  echo reprHighlighter.match(
    "127.0.1.1 bar 192.168.1.4 2001:0db8:85a3:0000:0000:8a2e:0370:7334 foo"
  )
