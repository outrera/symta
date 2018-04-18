GTable = No
GSpecs = No //kludge to recognize if/then/else
GError = Msg => | say Msg; halt
GInput = No
GOutput = No

type text_stream{T O} chars/T.list len/T.size off last/No row col origin/O
| DD = (#0d).char //allows reading windows line encoded files
| $chars <= $chars.skip{?><DD}
| $len <= $chars.size

text_stream.`{}` K = $chars.K
text_stream.peek = when $off < $len: $chars.($off)
text_stream.next =
| when $off < $len
  | $last <= $chars.($off)
  | $col++
  | $off++
  | when $last >< '\n'
    | $col <= 0
    | $row++
  | $last
text_stream.src = [$row $col $origin]
text_stream.error Msg = | say "at [$src]: [Msg]"; halt

type token{Sym Val Src P} symbol/Sym value/Val src/Src parsed/P
token_is What O = O.is_token and O.symbol >< What

//FIXME: optimize memory usage
add_lexeme Dst Pattern Type =
| when Pattern.end
  | Dst.0 <= Type
  | leave No
| [Cs@Next] = Pattern
| Kleene = 0
| case Cs [`&` X] | Cs <= X
                  | Next <= \(@$Cs $@Next)
          [`@` X] | Cs <= X
                  | Kleene <= 1
| when Cs.is_text: Cs <= Cs.list
| Cs = if Cs.is_list then Cs else [Cs]
| for C Cs{?code}
  | T = Dst.C
  | when no T: 
    | T <= if Kleene then Dst else dup 128 No
    | Dst.C <= T
  | add_lexeme T Next Type

init_tokenizer =
| when got GTable: leave No
| Digit = "0123456789"
| HexDigit = "0123456789ABCDEFabcdef"
| BinDigit = "01"
| HeadChar = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_?~"
| TailChar = "[HeadChar][Digit]"
| Ls = \(`+` `-` `*` `/` `%` `^` `.` `->` `|` `;` `,` `:` `=` `=>`
         `<=` `+=` `-=` `*=` `/=` `%=`
         `---` `+++` `&&&` `<<<` `>>>` `^^` `..` `++` `--`
         `><` `<>` `<` `>` `<<` `>>`
         `\\` `$` `@` `&` `@@`
         (() end)
         `)` (`(` $(R O => [`()` (read_list R O ')')]))
         `]` (`[` $(R O => [`[]` (read_list R O ']')]))
         `}` (`{` $(R O => [`{}` (read_list R O '}')]))
         (`'` $(R Cs => [text [`\\` @(read_string R 0 `'`)]])) //'
         (`"` $(R Cs => [splice (read_string R '[' '"')])) //"
         ($'`' $(R Cs => [symbol (read_string R 0 '`').0]))
         (`//` $&read_comment)
         ((`/` `*`) $&read_multi_comment)
         ((&(` ` `\n`)) $(R Cs => read_token R 1))
         ((`#` &$HexDigit) hex)
         ((`#` `#@` &$BinDigit) bin)
         ((&$Digit) integer)
         (($HeadChar @$TailChar) symbol)
         )
| Ss = \((`if` `if`) (`then` `then`) (`else` `else`) (`and` `and`) (`or` `or`) (`No` `void`))
| GTable <= dup 128 No
| GSpecs <= t
| for [A B] Ss: GSpecs.A <= B
| for L Ls
  | [Pattern Type] = if L.is_list then L else [L L]
  | when Pattern.is_text: Pattern <= Pattern.list
  | add_lexeme GTable Pattern Type

read_token R LeftSpaced =
| Src = R.src
| Head = R.peek
| Next = GTable
| Cur = No
| C = No
| Cs = []
| while 1
  | Cur <= Next
  | C <= R.peek
  | CC = if got C then C.code else 127
  | Next <= Next.CC
  | when no Next
    | Value = Cs.flip.text
    | Type = GSpecs.Value
    | when no Type: Type <= Cur.0
    | when Value >< '-' and LeftSpaced and C <> '\n' and C <> ' ':
      | Type <= \negate
    | when Type >< end and got C: Type <= 0
    | less Type:
      | when Value><'' and C.size><1:
        | C <= if CC>#d then "[C] (#[C.code.x])" else "no-printable (#[CC.x])"
      | R.error{"unexpected `[Value][C or '']`"}
    | when Type.is_fn
      | Value <= Type R Value
      | when Value.is_token: leave Value
      | Type <= Value.0
      | Value <= Value.1
    | leave: token Type Value Src 0
  | push C Cs
  | R.next

add_bars Xs =
| Ys = []
| First = 1
| while not Xs.end
  | X = pop Xs
  | [Row Col Orig] = X.src
  | S = X.symbol
  | when (Col >< 0 or First) and S <> `|` and S <> `then` and S <> `else`:
    | push (token '|' '|' [Row Col-1 Orig] 0) Ys 
    | First <= 0
  | push X Ys
| Ys.flip

tokenize R =
| Ts = []
| while 1
  | Tok = read_token R 0
  | when Tok^token_is{end}: leave Ts.flip^add_bars
  | push Tok Ts

read_list R Open Close =
| [Row Col Orig] = R.src
| Xs = []
| while 1
  | X = read_token R 0
  | when X^token_is{Close}: leave Xs.flip
  | when X^token_is{end}: GError "[Orig]:[Row],[Col]: unclosed `[Open]`"
  | Xs <= [X@Xs]

spliced_string_normalize Xs =
| Ys = Xs.skip{X => '' >< X}
| map Y Ys: if Y.is_text then token symbol Y [0 0 none] 0
            else if Y.is_token then Y
            else token '()' Y [0 0 none] 0

read_string R Incut End =
| L = []
| while 1
  | C = R.peek
  | less C >< Incut: R.next
  | case C
     `\\` | case R.next
             `n` | L <= ['\n' @L]
             `t` | L <= ['\t' @L]
             `\\` | L <= ['\\' @L]
             `[` | L <= ['[' @L]
             `]` | L <= [']' @L]
             `'` | L <= [`'` @L]
             `"` | L <= [`"` @L]
             C<&Incut+&End | L <= [C@L]
             No | R.error{'EOF in string'}
             Other | if Other><'`' then L <= ['`' @L]
                     else R.error{"Invalid escape code: [Other]"}
     &End | Ys = [L.flip.text]
          | when End >< '"': Ys <= spliced_string_normalize Ys
          | leave Ys
     &Incut | L <= L.flip.text
            | M = (read_token R 0).value
            | E = read_string R Incut End
            | leave: spliced_string_normalize [L M @E]
     No | R.error{'EOF in string'}
     Else | L <= [C@L]

is_comment_char C = got C and C <> '\n'
read_comment R Cs =
| while R.next^is_comment_char:
| read_token R 0

read_multi_comment R Cs =
| for(O=1; O > 0; ): case [R.next R.peek]
    [X No] | R.error{"`/*`: missing `*/`"}
    [`*` `/`] | O--; R.next
    [`/` `*`] | O++; R.next
| read_token R 0

parser_error Cause Tok =
| [Row Col Orig] = Tok.src
| say "[Orig]:[Row],[Col]: [Cause] [Tok.value or 'eof']"
| halt

expect What Head =
| less GInput.size: parser_error "missing [What] for" Head
| Tok = GInput.0
| less Tok^token_is{What}: parser_error "missing [What] for" Head
| pop GInput

parse_if Sym =
| Head = parse_xs
| expect `then` Sym
| Then = parse_xs
| expect `else` Sym
| Else = parse_xs
| [Sym Head Then Else]

parse_bar H =
| C = H.src.1
| Zs = []
| while not GInput.end
  | Ys = []
  | while not GInput.end and GInput.0.src.1 > C: push GInput^pop Ys
  | push Ys.flip^parse_tokens Zs
  | when GInput.end: leave [H @Zs.flip]
  | X = GInput.0
  | less X^token_is{'|'} and X.src.1 >< C: leave [H @Zs.flip]
  | pop GInput

parse_negate H =
| A = parse_mul or leave 0
| less A^token_is{integer} or A^token_is{hex} or A^token_is{float}: leave [H A]
| token A.symbol "-[A.value]" H.src [-A.parsed.0]

parse_term =
| when GInput.end: leave 0
| Tok = pop GInput
| when Tok.parsed: parser_error "already parsed token" Tok
| V = Tok.value
| P = case Tok.symbol
         escape+symbol+text | leave Tok
         splice | [(token symbol `"` Tok.src 0) @V^parse_tokens] //"
         integer | V.int
         hex | V.tail.int{16}
         bin | V.drop{2}.int{2}
         void | No
         `()` | parse_tokens V
         `[]` | [(token symbol `[]` Tok.src 0) @V^parse_tokens]
         `|` | leave Tok^parse_bar
         `if` | leave Tok^parse_if
         `-` | leave Tok^parse_negate
         Else | push Tok GInput
              | leave 0
| Tok.parsed <= [P]
| Tok

is_delim X = X.is_token and case X.symbol
             `:`+`=`+`<=`+`=>`+`if`+`then`+`else`+`+=`+`-=`+`*=`+`/=`+`%=`
             1



parse_op Ops =
| when GInput.end: leave 0
| V = GInput.0.symbol
| when no Ops.find{O => O><V}: leave 0
| pop GInput

binary_loop Ops Down E =
| O = parse_op Ops or leave E
| when O^token_is{`{}`}
  | As = parse_tokens O.value
  | As <= if got As.find{&is_delim} then [As] else As //allows Xs.map{X=>...}
  | O.parsed <= [`{}`]
  | leave: binary_loop Ops Down [O E @As]
| B = &Down or parser_error "no right operand for" O
| less O^token_is{'.'} and E^token_is{integer} and B^token_is{integer}:
  | leave: binary_loop Ops Down [O E B]
| V = "[E.value].[B.value]"
| F = token float V E.src [V^parse_float]
| leave: binary_loop Ops Down F

parse_binary Down Ops = binary_loop Ops Down: &Down or leave 0

parse_dollar =
| O = parse_op [`$` negate `\\` `@` `&` `@@`] or leave (parse_term)
| when O^token_is{negate}: leave O^parse_negate
| [O (parse_dollar or parser_error "no operand for" O)]
parse_dot = parse_binary &parse_dollar [`.` `^` `->` `{}`]
parse_suffix_loop Ops E =
| O = parse_op Ops or leave E
| parse_suffix_loop Ops [O E]
parse_suffix = parse_suffix_loop [`++` `--`]: parse_dot or leave 0
parse_prefix =
| O = parse_op [negate `\\` `@` `&` `@@`] or leave (parse_suffix)
| when O^token_is{negate}: leave O^parse_negate
| [O (parse_prefix or parser_error "no operand for" O)]
parse_pow = parse_binary &parse_prefix [`^^`]
parse_mul = parse_binary &parse_pow [`*` `/` `%`]
parse_add = parse_binary &parse_mul [`+` `-`]
parse_dots = parse_binary &parse_add [`..`]
parse_b_shift = parse_binary &parse_dots [`<<<` `>>>`]
parse_b_and = parse_binary &parse_b_shift [`&&&`]
parse_b_xor = parse_binary &parse_b_and [`+++` `---`]
parse_comma = parse_binary  &parse_b_xor [`,`]
parse_bool = parse_binary &parse_comma [`><` `<>` `<` `>` `<<` `>>`]

parse_logic =
| O = parse_op [`and` `or`] or leave (parse_bool)
| GOutput <= GOutput.flip
| P = GInput.locate{&is_delim} //hack LL(1) to speed-up parsing
| Tok = got P and GInput.P
| when no P or got [`if` `then` `else` ].locate{X => Tok^token_is{X}}:
  | GOutput <= [(parse_xs) GOutput O]
  | leave 0
| R = GInput.take{P}
| GInput <= GInput.drop{P}
| GOutput <= if Tok^token_is{`:`}
             then [[O GOutput.tail R^parse_tokens] GOutput.head]
             else [[O GOutput R^parse_tokens]]
| No

parse_delim =
| O = parse_op [`:` `=` `<=` `=>` `+=` `-=` `*=` `/=` `%=`] or leave (parse_logic)
| Pref = if GOutput.size > 0 then GOutput.flip else []
| GOutput <= [(parse_xs) Pref O]
| No

parse_semicolon =
| P = GInput.locate{X => X^token_is{`|`} or X^token_is{`;`}}
| M = when got P: GInput.P
| when no P or M^token_is{`|`}: leave 0
| L = parse_tokens GInput.take{P}
| R = parse_tokens GInput.drop{P+1}
| GInput <= []
| GOutput <= if R.size and R.0^token_is{`;`}
             then [@R.tail.flip L M]
             else [R L M]
| No

parse_xs =
| let GOutput []
  | parse_semicolon
  | named loop // FIXME: implement unwind_protect
    | while 1
      | X = parse_delim or leave loop GOutput.flip
      | when got X: push X GOutput

parse_tokens Input =
| let GInput Input
  | Xs = parse_xs
  | less GInput.end: parser_error "unexpected" GInput.0
  | Xs

parse_strip X =
| if X.is_token
  then | P = X.parsed
       | R = if P then parse_strip P.0 else X.value
       | R
  else if X.is_list
  then | less X.size: leave X
       | Head = X.head
       | Meta = when Head.is_token: Head.src
       | Ys = map V X: parse_strip V
       | when got Meta and Meta.2 <> '<none>': Ys <= meta Ys Meta
       | Ys
  else X

text.parse src/'<none>' =
| init_tokenizer
| R = parse_strip: parse_tokens: tokenize: text_stream Me Src
| if R.end then [[]] else R.0.tail

export
