import cligen
import std/[lexbase, streams]

type
    UpdateParserState = enum
        statePlainText, statePotentialExpansion
    UpdateParser = object of BaseLexer
        curtext: string
        state: UpdateParserState

proc open(L: var UpdateParser, input: Stream) =
    lexbase.open(L, input)
    L.curtext = ""
    L.state = statePlainText

proc close(L: var UpdateParser) =
    lexbase.close(L)

proc getNextFragment(parser: var UpdateParser): string = discard

proc expandupdate(text_tables: seq[string], output: string, file: string): int = discard


dispatch expandupdate