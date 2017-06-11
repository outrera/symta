non F = X => if F X then 0 else 1
no X = No >< X
got X = No <> X

_.`><` B = same Me B
_.`<>` B = not Me >< B
_.`<<` B = not B < Me
_.`>` B = B < Me
_.`>>` B = not Me < B

_.is_int = 0
int.is_int = 1

_.is_float = 0
float.is_float = 1

_.is_fn = 0
fn.is_fn = 1

_.is_list = 0
list.is_list = 1

_.is_text = 0
text.is_text = 1

//_.is_hard_list = 0
//list.is_hard_list = 1

_.copy = Me
list.copy = map X Me X

_.deep_copy = Me
list.deep_copy = map X Me X.deep_copy

methods Object = Object^methods_.table

_.`{}` F = $map{F}
fn.`{}` @As = As.apply{Me}


int.sign = if Me < 0 then -1
           else if Me > 0 then 1
           else 0

float.sign = if Me < 0.0 then -1.0
             else if Me > 0.0 then 1.0
             else 0.0

list.sign = map X Me X.sign

int.abs = if Me < 0 then -Me else Me

float.abs = if Me < 0.0 then -Me else Me

list.abs =
| R = 0.0
| map X Me: R += @float X*X
| R.sqrt

list.normalize = Me / $abs

list.neg = dup I $size -$I
list.`+` Ys = dup I $size $I+Ys.I
list.`-` Ys = dup I $size $I-Ys.I
list.`*` A = map X Me: X*A
list.`/` A = map X Me: X/A
list.`%` A = map X Me: X%A
list.float = map X Me: X.float
list.int = map X Me: X.int
list.round = Me{?round}


text.`<` B =
| less B.is_text: bad "cant compare string `[Me]` with [B]"
| AS = $size
| BS = B.size
| if AS < BS
  then | times I AS
         | AC = $I.code
         | BC = B.I.code
         | when AC <> BC: leave AC < BC
       | 1
  else | times I BS
         | AC = $I.code
         | BC = B.I.code
         | when AC <> BC: leave AC < BC
       | 0

text.is_upcase =
| times I $size
  | C = $I.code
  | when C < 'A'.code or 'Z'.code < C: leave 0
  | I++
| 1

text.is_downcase =
| times I $size
  | C = $I.code
  | when C < 'a'.code or 'z'.code < C: leave 0
  | I++
| 1

text.is_digit =
| times I $size
  | C = $I.code
  | when C < '0'.code or '9'.code < C: leave 0
  | I++
| 1

text.upcase =
| Ys = map Char $list
  | C = Char.code
  | if C < 'a'.code or 'z'.code < C then Char else (C - 'a'.code + 'A'.code).char
| Ys.text

text.downcase =
| Ys = map Char $list
  | C = Char.code
  | if C < 'A'.code or 'Z'.code < C then Char else (C - 'A'.code + 'a'.code).char
| Ys.text

text.title =
| less $size: leave Me
| if $0.is_upcase then Me else "[$0.upcase][$tail]"

_.is_keyword = 0
text.is_keyword = not: $size and $0.is_upcase

text.trim s/' ' i/0 l/1 r/1 =
| Xs = $list
| when L: 
  | It = case Xs [&S@Zs] Zs
  | while It: Xs <= It
| when R
  | Xs <= Xs.flip
  | It = case Xs [&S@Zs] Zs
  | while It: Xs <= It
  | Xs <= Xs.flip
| Xs.text

list.replace A B = Me{|&A=>B; X=>X}
text.replace A B = Me.list.replace{A B}.text

int.list = dup I Me: I //iota operator

int.map F = dup I Me: F I

int.keep F = Me.list.keep{F}
int.skip F = Me.list.skip{F}

list.i = dup I $size: [I Me^pop]

list.`.` K =
| times I K: Me <= $tail
| $head

list.del K = [@$take{K} @$drop{K+1}]
list.insert K V = [@$take{K} V @$drop{K}]
list.change K V = [@$take{K} V @$drop{K+1}]

list.x = $0
list.y = $1
list.z = $2

list.size =
| S = 0
| till $end
  | Me <= $tail
  | S++
| S

list.end = not $size

text.end = not $size

_bytes_.list = dup I $size $I

bytes.bytes = Me

list.bytes =
| N = $size
| as Ys N.bytes: times I N: Ys.I <= pop Me

list.utf8 = $bytes.utf8

list.head = $0

list.tail = $list.tail

list.`><` B =
| less B.is_list: leave 0
| till $end or B.end: less Me^pop >< B^pop: leave 0
| $end and B.end

hard_list.`><` B =
| less B.is_list: leave 0 //FIXME: cons_list B will be O(n^2) slow
| N = $size
| less N >< B.size: leave 0
| times I N: less $I >< B.I: leave 0
| 1

list.`<` Xs =
| A = 0
| B = 0
| times I $size:
  | A <= $I
  | B <= Xs.I
  | when A <> B: leave A < B
| leave A < B

list.`>` Xs =
| A = 0
| B = 0
| times I $size:
  | A <= $I
  | B <= Xs.I
  | when A <> B: leave A > B
| leave A > B

list.`<<` Xs =
| A = 0
| B = 0
| times I $size:
  | A <= $I
  | B <= Xs.I
  | when A <> B: leave A << B
| leave A << B

list.`>>` Xs =
| A = 0
| B = 0
| times I $size:
  | A <= $I
  | B <= Xs.I
  | when A <> B: leave A >> B
| leave A >> B

list.flip =
| N = $size
| Ys = dup N
| while N > 0
  | N--
  | Ys.N <= pop Me
| Ys

hard_list.flip =
| N = $size
| dup N
  | N--
  | $N

text.flip = $list.flip.text

list.transpose = Me.0.size{}{I=>Me.map{?.I}}

list.map F = dup $size: F Me^pop
hard_list.map F = dup I $size: F $I
text.map F = $list.map{F}

list.fold Run F =
| for X Me: Run <= F Run X
| Run

list.e F = till $end: F Me^pop
hard_list.e F = times I $size: F $I

list.sum =
| S = 0
| till $end: S += pop Me
| S

hard_list.sum =
| S = 0
| times I $size: S += $I
| S

list.count F =
| C = 0
| till $end: when F Me^pop: C++
| C

hard_list.count F =
| C = 0
| I = 0
| times I $size: when F $I: C++
| C

list.keep F =
| Ys = []
| if F.is_fn
  then for X Me: when F X: Ys <= [X@Ys]
  else for X Me: when F >< X: Ys <= [X@Ys]
| Ys.flip

list.skip F =
| Ys = []
| if F.is_fn
  then for X Me: less F X: Ys <= [X@Ys]
  else for X Me: less F >< X: Ys <= [X@Ys]
| Ys.flip

list.join =
| Rs = dup $map{?size}.sum
| I = 0
| for Ys Me: for Y Ys: Rs.(I++) <= Y
| Rs

_list_.list = Me

list.list =
| N = $size
| Ys = dup N
| times I N: Ys.I <= pop Me
| Ys

list.apply F = $list.apply{F}
list.apply_method F = $list.apply_method{F}

list.text @As =
| R = $list
| if As.size then R.text{As.0} else R.text

text.text = Me

list.split S =
| F = if S.is_fn then S else X => S >< X
| Ys = []
| P = $locate{F}
| while got P
  | Ys <= [$take{P}@Ys]
  | Me <= $drop{P+1}
  | P <= $locate{F}
| [Me@Ys].flip

text.split F = $list.split{F}.map{X=>X.text}

text.all F = Me.list.all{F}
text.any F = Me.list.any{F}

text.lines = $split{'\n'}

text.get = get_file_ Me
text.get_text = get_text_file_ Me
text.set Value =
| if Value.is_text then set_text_file_ Me Value else set_file_ Me Value.bytes
| 0
text.exists = file_exists_ Me
text.time = file_time_ Me
text.mkpath = mkpath_ Me

text.paths @As =
| Path = if $last >< '/' then Me else "[Me]/"
| Xs = if As.size then $items{all} else $items
| map X Xs "[Path][X]"

text.urls = Me.paths{}{?url}

text.folders = Me.items{}{?url}.keep{is.[_ '' '']}{?0.lead}

text.url =
| Name = ""
| Ext = ""
| Xs = $list.flip
| Sep = Xs.locate{?><'/'}
| Dot = Xs.locate{?><'.'}
| when got Dot and (no Sep or Dot < Sep):
  | Ext <= Xs.take{Dot}.flip.text
  | Xs <= Xs.drop{Dot+1}
  | when got Sep: Sep -= Dot+1
| Folder = No
| Name = No
| if got Sep
  then | Folder <= "[Xs.drop{Sep+1}.flip.text]/"
       | Name <= Xs.take{Sep}.flip.text
  else | Folder <= ''
       | Name <= Xs.flip.text
| [Folder Name Ext]

list.unurl =
| [Folder Name Ext] = Me
| when Ext <> '': Ext <= ".[Ext]"
| "[Folder][Name][Ext]"

main_root = (main_lib).url.0

list.take N = dup N: Me^pop
hard_list.take N = dup I N $I

list.drop N =
| times I N Me^pop
| Me

hard_list.drop S = dup $size-S: $|S++

text.drop S = $list.drop{S}.text
text.take S = $list.take{S}.text
text.last = $($size-1)
text.head = $0
text.tail = $drop{1}
text.lead = $take{$size-1}

list.last = $($size-1)
list.suf X = [@Me X]
list.lead = $take{$size-1}

list.cut P S = $drop{P}.take{S}
text.cut P S = $drop{P}.take{S}

text.keep Item = $list.keep{Item}.text
text.skip Item = $list.skip{Item}.text

_.rmap F = F Me
list.rmap F = map X Me X.rmap{F}

list.infix Item = // intersperse from Haskell
| N = $size*2-1
| if N < 0 then [] else dup I N: if I%2 then Item else Me^pop

list.locate F =
| less F.is_fn: F <= (X => F >< X)
| for(I=0; not $end; I++): when F Me^pop: leave I

hard_list.locate F =
| if F.is_fn then times I $size: when F $I: leave I
  else times I $size: when F >< $I: leave I

text.locate F =
| if F.is_fn then times I $size: when F $I: leave I
  else times I $size: when F >< $I: leave I

list.find F =
| if F.is_fn
  then for(I=0; not $end; I++):
  | It = Me^pop; when F It: leave It
  else for(I=0; not $end; I++):
  | It = Me^pop
  | when F><It: leave It

hard_list.find F =
| if F.is_fn
  then | times I $size:
         | It = $I
         | when F It: leave It
  else | times I $size:
         | It = $I
         | when F><It: leave It

text.list = dup I $size $I

list.group N =
| Y = []
| Ys = []
| I = 0
| till $end
  | push Me^pop Y
  | I++
  | when I >< N
    | push Y.flip Ys
    | Y <= []
    | I <= 0
| when Y.size: push Y.flip Ys
| Ys.flip

list.all F =
| if F.is_fn then for X Me: less F X: leave 0
  else for X Me: less F >< X: leave 0
| 1

list.any F =
| if F.is_fn then for X Me: when F X: leave 1
  else for X Me: when F >< X: leave 1
| 0

list.max =
| when $end: leave No
| M = $head
| for X Me: when X > M: M <= X
| M

list.min =
| when $end: leave No
| M = $head
| for X Me: when X < M: M <= X
| M

HexChars = '0123456789ABCDEF'

int.x =
| less Me: leave '0'
| Cs = []
| S = ''
| when Me < 0
  | S <= '-'
  | Me <= -Me
| while Me > 0
  | Cs <= [HexChars.(Me%16) @Cs]
  | Me /= 16
| [S@Cs].text

_.as_text = "#([Me^typename] [Me^address.x])"

void.as_text = 'No'

int.as_text =
| less Me: leave '0'
| Cs = []
| S = ''
| when Me < 0
  | S <= '-'
  | Me <= -Me
| while Me > 0
  | Cs <= [HexChars.(Me%10) @Cs]
  | Me /= 10
| [S@Cs].text

plain_char C =
| N = C.code
| if   ('a'.code << N and N << 'z'.code)
    or ('A'.code << N and N << 'Z'.code)
    or ('0'.code << N and N << '9'.code)
    or '_'.code >< N
  then 1
  else 0

text.as_text =
| less $size: leave '``'
| Cs = []
| Q = 0
| for C Me
  | less plain_char C: Q <= 1
  | when C >< '`': C <= '\\`'
  | push C Cs
| if Q then ['`' @['`' @Cs].flip].text else Me

list.as_text = "([(map X Me X.as_text).text{' '}])"

_.textify_ = $as_text
text.textify_ = Me

say Text = say_ "[Text]\n"
bad Text =
| say_ "bad: [Text]\n"
| say ''
| say 'Stack Trace:'
| ST = stack_trace
| for X ST.tail: say "    [X]"
| halt

// hashtable
type table.no_copy{@table_ Size} buckets/(dup Size No)
table.`.` K =
| Bs = $buckets
| H = K.hash%Bs.size
| Xs = Bs.H
| when no Xs: leave No
| for X Xs: when X.0 >< K: leave X.1
| No
table.`=` K V =
| Bs = $buckets
| H = K.hash%Bs.size
| Xs = Bs.H
| if no Xs then Bs.H <= [[K V]]
  else | Old = Xs.find{X => X.0><K}
       | if no Old then Bs.H <= [[K V]@Xs]
         else Old.1 <= V
| No
table.del K =
| Bs = $buckets
| H = K.hash%Bs.size
| Xs = Bs.H
| when no Xs: leave No
| L = Xs.locate{X => X.0><K}
| when got L: Bs.H <= $Xs.L
| Me
table._ Method Args =
| if Args.size > 1
  then Args.0.(Method^_method_name.tail) <= Args.1 // strip `assign indicator`
  else Me.(Method^_method_name)
table.size = $buckets.map{X => if got X then X.size else 0}.sum
table.list = $buckets.skip{No}.join
table.map F = $list.map{F}
table.as_text = "#t{[$list{}{?0}]}"

table.copy = $list.table
table.deep_copy = $list.table

list.table =
| S = $size*2
| T = t size/(if S < 3 then 3 else S)
| for [K V] Me: T.K <= V
| T

list.uniq =
| Seen = t size/($size*2)
| $skip{X => got Seen.X or (Seen.X <= 1) and 0}

text.pad Count Item =
| X = "[Item]"
| when X.size > 1: bad "pad item: [X]"
| N = Count.abs - $size
| when N < 0: bad "text is larger than [Count.abs]: '[Me]'"
| Pad = @text: dup N X
| if Count < 0 then "[Pad][Me]" else "[Me][Pad]"

list.pad Count Item =
| N = Count.abs - $size
| when N < 0: bad "list is larger than [Count.abs]: '[Me]'"
| Pad = dup N Item
| if Count < 0 then [@Pad @Me] else [@Me @Pad]


int.digits @Base =
| B = if Base.end then 10 else Base.head
| Ys = []
| while Me > 0
  | push Me%B Ys
  | Me /= B
| Ys.list

list.digits @Base =
| B = if Base.end then 10 else Base.head
| R = 0
| for X Me
  | R *= B
  | R += X
| R

type macro{@new_macro N E} name/N expander/E

type meta.~{O M} object_/O meta_/M
_.meta_ = No
meta._ Method Args =
| Args.0 <= $object_
| Args.apply_method{Method}

LCG_Seed = No
LCG_M = 2147483647
LCG_M_F = LCG_M.float
LCG_A = 16807
LCG_B = 0

lcg_init Seed =
| LCG_Seed <= Seed
| 10.rand
| No

int.rand =
| LCG_Seed <= (LCG_Seed*LCG_A + LCG_B) % LCG_M
| @int: @round: LCG_Seed.float*$float/LCG_M_F

float.rand =
| LCG_Seed <= (LCG_Seed*LCG_A + LCG_B) % LCG_M
| LCG_Seed.float/LCG_M_F*Me

list.rand = $(@rand $size-1)

GGensymCount = 0
text.rand = "[Me]__[GGensymCount++]"

lcg_init: time

list.shuffle =
| Xs = $copy
| N = Xs.size
| while N > 1
  | N--
  | R = N.rand
  | X = Xs.R
  | Xs.R <= Xs.N
  | Xs.N <= X
| Xs


IValue = 0
IParent = 1
ILeft = 2
IRight = 3

merge H1 H2 =
| less H1: leave H2
| less H2: leave H1
| when H2.IValue < H1.IValue:
  | T = H1
  | H1 <= H2
  | H2 <= T
| if 1.rand
  then | H1.ILeft <= merge H1.ILeft H2
       | when H1.ILeft: H1.ILeft.IParent <= H1
  else | H1.IRight <= merge H1.IRight H2
       | when H1.IRight: H1.IRight.IParent <= H1
| H1

sort_asc Xs =
| Root = 0
| for X Xs
  | Root <= merge [X 0 0 0] Root
  | Root.IParent <= 0
| dup Xs.size
  | V = Root.IValue
  | Root <= merge Root.ILeft Root.IRight
  | V

list.sort @As = 
| F = No
| case As
  [A] | F <= A
  [] | leave: sort_asc Me
  Else | bad "list.sort: invalid number of arguments"
| merge H1 H2 =
  | less H1: leave H2
  | less H2: leave H1
  | when F H2.IValue H1.IValue:
    | T = H1
    | H1 <= H2
    | H2 <= T
  | if 1.rand
    then | H1.ILeft <= merge H1.ILeft H2
         | when H1.ILeft: H1.ILeft.IParent <= H1
    else | H1.IRight <= merge H1.IRight H2
         | when H1.IRight: H1.IRight.IParent <= H1
  | H1
| Root = 0
| for X Me
  | Root <= merge [X 0 0 0] Root
  | Root.IParent <= 0
| dup $size
  | V = Root.IValue
  | Root <= merge Root.ILeft Root.IRight
  | V

list.sortBy F = $sort{?^F < ??^F}

//= parse text as integer; an optional argument provides Radix
text.int @Radix =
| Rdx = 10
| when Radix.size: Rdx <= Radix.0
| T = Me.upcase
| N = $size
| I = 0
| Sign = if $I >< '-'
         then | I++
              | -1
         else 1
| R = 0
| Base = '0'.code
| AlphaBase = 'A'.code - 10
| for(; I < N; I++)
  | C = T.I.code
  | V = if '0'.code << C and C << '9'.code then C - Base else C - AlphaBase
  | R <= R*Rdx + V
| R*Sign

list.u4 = $3*#1000000 + $2*#10000 + $1*#100 + $0
list.u4b = $0*#1000000 + $1*#10000 + $2*#100 + $3
list.s4 = as R $u4: when R&&&#80000000: R-=#100000000
list.s4b = as R $u4b: when R&&&#80000000: R-=#100000000

list.u2 = $1*#100 + $0
list.u2b = $0*#100 + $1
list.s2 = as R $u2: when R&&&#8000: R-=#10000
list.s2b = as R $u2b: when R&&&#8000: R-=#10000

int.u4 = [Me%256 Me/#100%256 Me/#10000%256 Me/#1000000%256]
int.u4b = [Me/#1000000%256 Me/#10000%256 Me/#100%256 Me%256]
int.s4 =
| when Me < 0: Me += #100000000
| [Me%256 Me/#100%256 Me/#10000%256 Me/#1000000%256]
int.s4b =
| when Me < 0: Me += #100000000
| [Me/#1000000%256 Me/#10000%256 Me/#100%256 Me%256]

int.u2 = [Me%256 Me/#100%256]
int.u2b = [Me/#100%256 Me%256]
int.s2 = 
| when Me < 0: Me += #10000
| [Me%256 Me/#100%256]
int.s2b =
| when Me < 0: Me += #10000
| [Me/#100%256 Me%256]

int.in Start End = Start << Me and Me < End
list.in [RX RY RW RH] = $0.in{RX RX+RW} and $1.in{RY RY+RH}

int.clip A B = if Me < A then A
               else if Me > B then B
               else Me

float.clip A B = if Me < A then A
                 else if Me > B then B
                 else Me

list.init Src = times I $size: $I <= Src.I

list.div F =
| R = t
| for X Me
  | K = F{X}
  | Xs = R.K
  | R.K <= if got Xs then [X@Xs] else [X]
| R{[?0 ?1.flip]}.table

list.xs Is = Is{$?}
table.xs Is = Is{$?}

list.hash =
| H = 0
| for X Me: H <= (H<<<1) +++ X.hash
| if H<0 then -H else H

list.clear Value = times I $size: Me.I <= Value

type iter{base p}
iter.end = $base.size><$p
iter.`++` = $base.($p++)
iter.`--` = $base.($p--)
iter.head = $base.$p
iter.`.` N = $base.($p+N)
iter.`=` N V = $base.($p+N) <= V
iter.`+` N = iter $base $p+N

list.iter = iter $list 0

export non say bad no got table_ new_macro meta main_root methods
