## This module defines colors and styles of variables in string.
##
## Mainly detects variables with regex when `newTuiConsoleOptions(auto_colorize = true)`.
##
## - Init:
##   - newTuiHighlighter_
## - Var:
##   - reprHighlighter_
##
## Parts of this file is heavily inspired from the [rich library](https://github.com/Textualize/rich).
## Please refer to [their licence](https://github.com/Textualize/rich/blob/master/LICENSE) as well.
##
## - Styles
##   - https://github.com/Textualize/rich/blob/master/rich/default_styles.py
##     ([permalink](https://github.com/Textualize/rich/blob/68224905f5dc7a3c765e04aba0460b75a95f5004/rich/default_styles.py))
##
## - Regex
##   - https://github.com/Textualize/rich/blob/master/rich/highlighter.py
##     ([permalink](https://github.com/Textualize/rich/blob/68224905f5dc7a3c765e04aba0460b75a95f5004/rich/highlighter.py))

import std/tables
import std/options
import std/terminal
import std/sequtils
import std/strutils

import regex
import tuistyles
import utils

let style_lookup = {
  "repr.ellipsis": newTuiStyles(color = fgYellow),
  "repr.indent": newTuiStyles(color = fgGreen, styles = @[styleDim]),
  "repr.error": newTuiStyles(color = fgRed, styles = @[styleBlink]),
  "repr.str": newTuiStyles(color = fgGreen),
  "repr.brace": newTuiStyles(styles = @[styleBlink]),
  "repr.comma": newTuiStyles(styles = @[styleBlink]),
  "repr.ipv4": newTuiStyles(styles = @[styleBlink, styleBright], color = fgGreen),
  "repr.ipv6": newTuiStyles(styles = @[styleBlink, styleBright], color = fgGreen),
  "repr.eui48": newTuiStyles(styles = @[styleBlink, styleBright], color = fgGreen),
  "repr.eui64": newTuiStyles(styles = @[styleBlink, styleBright], color = fgGreen),
  "repr.tag_start": newTuiStyles(styles = @[styleBlink]),
  "repr.tag_name": newTuiStyles(color = fgMagenta, styles = @[styleBlink, styleBright]),
  "repr.tag_contents": newTuiStyles(),
  "repr.tag_end": newTuiStyles(styles = @[styleBlink]),
  "repr.attrib_name": newTuiStyles(color = fgYellow),
  "repr.attrib_equal": newTuiStyles(styles = @[styleBlink]),
  "repr.attrib_value": newTuiStyles(color = fgMagenta),
  "repr.number": newTuiStyles(color = fgCyan, styles = @[styleBlink]),
  "repr.number_complex": newTuiStyles(color = fgCyan, styles = @[styleBlink]),
  "repr.bool_true": newTuiStyles(color = fgGreen, styles = @[styleItalic, styleBright]),
  "repr.bool_false": newTuiStyles(color = fgRed, styles = @[styleItalic, styleBright]),
  "repr.none": newTuiStyles(color = fgMagenta, styles = @[styleItalic]),
  "repr.url": newTuiStyles(styles = @[styleUnderscore, styleBright], color = fgBlue),
  "repr.uuid": newTuiStyles(color = fgYellow, styles = @[styleBright]),
  "repr.call": newTuiStyles(color = fgMagenta, styles = @[styleBlink]),
  "repr.path": newTuiStyles(color = fgMagenta),
  "repr.filename": newTuiStyles(color = fgMagenta, styles = @[styleBright]),
}.toTable()

type
  TuiHighlighter* = ref object of RootObj
    ## .. importdoc:: tuistyles.nim
    ## Class to detect variables inside given TuiStyles_ and returns new `seq[TuiStyles]`
    ## with TuiStyles_ applied based on regex defined in `highlights` and `lookup`.
    ##
    ## Init. newTuiHighlighter_
    prefix*: string
    highlights*: seq[Regex2]
    lookup*: TableRef[string, TuiStyles]
  MatchResult* = ref object of RootObj
    ## .. importdoc:: tuistyles.nim
    ## Stores what kind of TuiStyles_ should be applied to texts.
    ## - `text`: seq of chars that belong to this MatchResult_
    ## - `optTuiStyles`
    ## - `hlKey`: key name of the TuiStyles_ from `style_lookup`
    ##
    ## Ref. assign_, match_
    text*: string
    optTuiStyles*: Option[TuiStyles]
    hlKey*: string
  MatchSeq* = object
    ## .. importdoc:: tuistyles.nim
    ## `ids.len == text.len`.
    ##
    ## Value of each id points to the index of which MatchResult_ inside pool that char belongs to.
    ## If no TuiStyles_ should be applied, value is `-1`
    ids*: seq[int]
    pool*: seq[MatchResult]
    null: MatchResult

func lookup*(self: MatchSeq, idx: int): MatchResult =
  ## Return corresponding MatchResult_ of `idx`th character
  ## of input text.
  ##
  ## If `self.ids[idx]` is `-1`, returns MatchResult_
  ## where `result.optTuiStyles.isNone == true`.
  ##
  ## Ref. MatchResult_, assign_
  var id = self.ids[idx]
  if self.pool.low <= id and id <= self.pool.high:
    return self.pool[id]
  return self.null

func `[]`*(self: MatchSeq, idx: int): MatchResult =
  ## Syntax sugar for lookup_
  ##
  ## .. code-block:: Nim
  ##    let self: MatchSeq
  ##    assert self.lookup(0) == self[0] # `==` is not defined for MatchResult tho.
  self.lookup(idx)

func assign*(self: var MatchSeq, idx: int, id: int) =
  ## Assign MatchResult_ for `idx`th character in input text.
  ## `id` should be the index of MatchResult_ in `pool` sequence.
  ##
  ## Ref. `[]`_, lookup_, match_
  runnableExamples:
    ## Assigns "repr.number" to `100`.
    import std/[sequtils, options, tables, terminal]
    import tuicrown/tuistyles
    let text = """100, "string""""
    let style_lookup = {"repr.number": newTuiStyles(color = fgCyan, styles = @[styleBlink])}.totable()
    let firstResult = MatchResult(text: "100", optTuiStyles: some(style_lookup["repr.number"]), hlKey: "repr.number")
    var matchseq = newMatchSeq(text.len)
    matchseq.pool.add(firstResult)
    for i in 0..<3:
      matchseq.assign(i, matchseq.pool.high)
  assert self.pool.low <= id and id <= self.pool.high
  self.ids[idx] = id

func len*(self: MatchSeq): int = self.ids.len
  ## Length of input text.

func newMatchSeq*(text_len: int): MatchSeq =
  MatchSeq(ids: newSeq[int](text_len).mapIt(-1), pool: newSeq[MatchResult](),
    null: MatchResult(text: "", optTuiStyles: none(TuiStyles), hlKey: ""))

proc newTuiHighlighter*(prefix = "", highlights = newSeq[seq[string]]()): TuiHighlighter =
  ## Create new highlighter
  ##
  ## See reprHighlighter_ for an example.
  ##
  ## Ref. reprHighlighter_
  result = TuiHighlighter(prefix: prefix, highlights: newSeq[Regex2](), lookup: style_lookup.pairs().toSeq.newTable())
  for hl in highlights:
    result.highlights.add(hl.join("|").re2())

func updateLookup*(self: TuiHighlighter, k: string, v: TuiStyles) =
  ## Append new regex patterns and its key.
  self.lookup[k] = v

func updateLookup*(self: TuiHighlighter, t: TableRef[string, TuiStyles]) =
  ## Append multiple new regex patterns and their keys at once.
  for (k, v) in t.pairs():
    self.updateLookup(k, v)

func match*(self: TuiHighlighter, text: string): MatchSeq {.discardable.} =
  ## Match given string `text` against pre-defined regexes and apply styles.
  ##
  ## .. importdoc:: tuisegment.nim
  ## Ref. [proc colorize] for usage example.
  result = newMatchSeq(text.len)
  for reg in self.highlights:
    for m in text.findAll(reg):
      for name in m.namedGroups.keys:
        var lookup = self.prefix & name
        if not self.lookup.hasKey(lookup):
          continue
        for bounds in m.group(name):
          if bounds.a > bounds.b: continue
          var subtext = text[bounds]
          result.pool.add(MatchResult(text: subtext, optTuiStyles: some(self.lookup[lookup]), hlKey: lookup))
          var idx = result.pool.high
          for it in bounds:
            if result.lookup(it).optTuiStyles.isNone or result.lookup(it).text.len < subtext.len:
              result.assign(it, idx)

let reprHighlighter* = newTuiHighlighter("repr.", @[
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
]) ## \
  ## TuiHighlighter_ for variables and other symbols.
  ##
  ## - Usage (`tag_name`, `example`):
  ##   - tag_start, tag_name, tag_contents, tag_end: `<div>content</div>`
  ##   - attrib_name, attrib_value: `a=100`, `b="x"`
  ##   - brace: `(, ), {, }, [, ]`
  ##   - ipv4: `127.0.0.1`
  ##   - ipv6: `2001:0db8:0000:0000:0000:8a2e:0370:7334`, `2001:db8::8a2e:370:7334`
  ##   - eui64: <Extended Unique Identifier 64-bit>
  ##   - uuid: `123e4567-e89b-12d3-a456-426614174000`
  ##   - call: `function`(...
  ##   - bool_true, bool_false: `true`, `false`
  ##   - ellipsis: `...`
  ##   - number_complex: `1+2j`
  ##   - number: `100`, `0.001`, `1e-6`
  ##   - path: `/path/to/file`
  ##   - str: `"string"`
  ##   - url: `http://www.example.com`

mainExamples:
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
