GEnv = No
GOut = No // where resulting assembly code is stored
GCurFn = No // unique name of current function
GCurProperFn = No // unique name of current function with prologue
GFnMeta = No
GInits = No // stuff called on module initialization
GBytes = No
GStrings = No
GRTypes = No // resolved types
GRTypesCount = No
GTypeParams = No
GImports = No
GImportsCount = No
GTexts = No
GTextsMap = No
GTextsCount = No
GMethods = No //resolved methods
GMethodsCount = No
GImportLibs = No
GImportLibsCount = No
GFns = No
GClosure = No // other lambdas, this lambda references
GBases = No
GUniquifyStack = No
GHoistedTexts = No
GSrc = [0 0 unknown]
GAll = @rand all

type fnmeta{name/0 size/0 nargs/0 origin/0}
  name/Name size/Size /*closure size*/ nargs/Nargs origin/Origin

ssa @As = | push As GOut
          | No

ssaI @As = | push As GInits
           | No

get_parent_index Parent =
| P = GClosure.0.locate{E => Parent >< E}
| when got P: leave P
| Parents = GClosure.head
| GClosure <= [[@Parents Parent] @GClosure.tail]
| Parents.size

path_to_sym X Es =
| when Es.end: leave No
| [Head@Tail] = Es
| when case Head [U@Us] U >< GAll // reference to the whole arg-list?
  | Head <= Head.1
  | less Head.0 >< X: leave (path_to_sym X Tail)
  | when Es^address >< GEnv^address: leave [GAll No] // argument of the current function
  | leave [GAll (get_parent_index Head.1)]
| P = Head.locate{V => X >< V.0}
| when no P: leave (path_to_sym X Tail)
| when Es^address >< GEnv^address: leave [P No] // argument of the current function
| [P (get_parent_index Head.P.1)]

ssa_symbol K X Value =
| case (path_to_sym X GEnv)
     [Pos Parent]
       | Base = if got Parent then "B".rand else \E
       | when got Parent
         | ssa var Base
         | ssa load Base \P Parent
       | when Pos >< GAll
         | when got Value: compiler_error "cant set [X]"
         | ssa tagged K Base \T_LIST
         | leave No
       | when no Value: leave (ssa ldarg K Base Pos)
       | if Base >< \E and GBases.size >< 1
         then ssa starg Base Pos Value
         else ssa lift Base Pos Value // must be copied into parent environment
     Else
       | compiler_error "unknown symbol `[X]` (compiler bug)"

cstring_bytes S = [@S.list.map{C => C.code} 0]

ssa_cstring Str =
| It = GStrings.Str
| when got It: leave It
| as Name 'b'.rand:
  | GStrings.Str <= Name
  | push [Name Str^cstring_bytes] GBytes

ssa_var Name = as V Name.rand: ssa var V

ev X = as R 'r'^ssa_var: ssa_expr R X

ssa_quote K X = if X.is_text then ssa_expr K GHoistedTexts.X
                else if X.is_list then compiler_error "ssa_quote: got list [X]"
                else ssa_expr K X

ssa_resolve Name = [Name GCurFn]

ssa_fn_body K F Args Body O Prologue Epilogue =
| LocalEnv = if Args.is_text
             then [[GAll [Args F]] @GEnv]
             else [Args.map{A=>[A F]} @GEnv]
| let GBases   [[]]
      GOut     []
      GCurFn   F
      GEnv     LocalEnv
      GClosure [[]@GClosure]
  | when Prologue: ssa label GCurFn
  | when Prologue
    | NArgs = if Args.is_text then -1 else Args.size 
    | GFnMeta.F <= fnmeta nargs/NArgs origin/GSrc
    | when NArgs<>-1: ssa check_nargs NArgs
  | when no K: K <= ssa_var result
  | if Prologue then let GCurProperFn GCurFn | ssa_expr K Body
    else ssa_expr K Body
  | when Epilogue: ssa return K
  | [GOut GClosure.0]

// FIXME:
// check if we really need new closure here, because in some cases we can reuse parent's closure
// a single argument to a function could be passed in register, while a closure would be created if required
// a single reference closure could be itself held in a register
// for now we just capture required parent's closure
ssa_fn K Args Expr O =
| F = @rand f
| [Body Cs] = ssa_fn_body No F Args Expr O 1 1
| push Body GFns
| NParents = Cs.size
| ssa closure K F NParents
| GFnMeta.F.size <= NParents
| for [I C] Cs.i: if C^address >< GCurFn^address // self?
                  then ssa stor K I \E
                  else ssa copy K I \P C^get_parent_index

ssa_if K Cnd Then Else =
| ThenLabel = @rand `then`
| EndLabel = @rand endif
| ssa branch Cnd^ev ThenLabel
| ssa_expr K Else
| ssa jmp EndLabel
| ssa local ThenLabel
| ssa_expr K Then
| ssa local EndLabel

//FIXME: currently hoisting may clobber some toplevel syms;
//       make new syms valid only downstream
ssa_hoist_decls Expr Hoist = // combine layered lets into single one
| less Expr.is_list: leave Expr
| case Expr
     [_fn @Xs] | Expr
     [[_fn As @Xs] @Vs]
       | Vs <= Vs.map{V => ssa_hoist_decls V Hoist}
       | if As.is_text
         then | Hoist [As]
              | [_progn [_set As [_list @Vs]]
                        @Xs.map{X => ssa_hoist_decls X Hoist}]
         else | Hoist As
              | [_progn @As.map{A => [_set A Vs^pop]}
                        @Xs.map{X => ssa_hoist_decls X Hoist}]
     Xs | Xs.map{X => ssa_hoist_decls X Hoist}

ssa_let K Args Vals Xs =
| Body = ssa_hoist_decls [_progn @Xs]: Hs =>
         | Args <= [@Args @Hs]
         | Vals <= [@Vals @Hs.map{H => 0}]
| when Args.size >< 0
  | ssa_expr K Body
  | leave No
| F = @rand f
| [SsaBody Cs] = ssa_fn_body K F Args Body [] 0 0
| NParents = Cs.size
| P = ssa_var p // parent environment
| ssa losure P NParents
| for [I C] Cs.i: if C^address >< GCurFn^address // self?
                  then ssa stor P I \E
                  else ssa copy P I \P C^get_parent_index
| E = ssa_var env
| ssa arl E Args.size
| for [I V] Vals.i: ssa starg E I V^ev
| SaveP = ssa_var save_p
| SaveE = ssa_var save_e
| ssa move SaveP \P
| ssa move SaveE \E
| ssa move \E E
| ssa move \P P
| for S SsaBody.flip: push S GOut
| ssa move \P SaveP
| ssa move \E SaveE

ssa_apply K F As =
| case F [_fn Bs @Body]: less Bs.is_text: leave: ssa_let K Bs As Body
| ssa bpush
| let GBases [[] @GBases]
  | H = ev F
  | Vs = map A As: ev A
  | E = ssa_var env
  | ssa arl E As.size
  | for [I V] Vs.i: ssa starg E I V
  | if F.is_keyword then ssa call K H else ssa call_tagged K H

resolve_type Name =
| It = GRTypes.Name
| when got It: leave It.1
| N = GRTypesCount++
| R = "ty\[[N]\]"
| GRTypes.Name <= [N R Name^ssa_cstring]
| R

resolve_method Name =
| It =  GMethods.Name
| when got It: leave It.1
| N = GMethodsCount++
| R = "mt\[[N]\]"
| GMethods.Name <= [N R Name^ssa_cstring]
| R

ssa_import K Lib Symbol =
| Lib <= Lib.1
| Symbol <= Symbol.1
| Key = "[Lib]::[Symbol]"
| Im = GImports.Key
| when no Im:
  | N = GImportsCount++
  | R = "im\[[N]\]"
  | Im <= [N R Key GImportLibs.Lib Symbol^ssa_cstring]
  | GImports.Key <= Im
| ssa move K Im.1

ssa_apply_method K Name O As =
| ssa bpush
| let GBases [[] @GBases]: named block
  | As <= [O@As]
  | Vs = map A As: ev A
  | E = ssa_var env
  | ssa arl E As.size
  | for [I V] Vs.i: ssa starg E I V
  | ssa mcall K Vs.0 Name.1^resolve_method

ssa_set K Place Value =
| R = ev Value
| ssa_symbol No Place R
| ssa move K R

// FIXME: _label should be allowed only inside of _progn
ssa_progn K Xs =
| when Xs.end: Xs <= [[]]
| D = 'dummy'
| for X Xs: case X [_label Name] | GBases <= [[Name @GBases.head] @GBases.tail]
| till Xs.end
  | X = pop Xs
  | when Xs.end: D <= K
  | ssa_expr D X
  | when Xs.end and case X [_label@Zs] 1: ssa_atom D No

compiler_error Msg =
| [Row Col Orig] = GSrc
| say "[Orig]:[Row],[Col]: [Msg]"
| halt

expr_symbols_sub Expr Syms =
  if Expr.is_text then Syms.Expr <= 1
  else when Expr.is_list: map X Expr: expr_symbols_sub X Syms 

expr_symbols Expr =
| Syms = t size/1000
| expr_symbols_sub Expr Syms
| Syms

uniquify_let Xs =
| case Xs [[_fn As @Body] @Vs]
  | when As.is_text: leave Xs
  | when As.size <> Vs.size: compiler_error "bad number of arguments in [Xs]"
  | when no Vs.find{V => case V [_import X Y] 1}: leave Xs
  | Used = expr_symbols Body
  | NewAs = []
  | NewVs = []
  | till As.end
    | A = pop As
    | V = pop Vs
    | case V
        [_import [_quote X] [_quote Y]]
          | when no GImportLibs.X: GImportLibs.X <= GImportLibsCount++
          | when got Used.A
            | push A NewAs
            | push V NewVs
        Else
          | push A NewAs
          | push V NewVs
  | As <= NewAs.flip
  | Vs <= NewVs.flip
  | Xs <= [[_fn As @Body] @Vs]
| Xs

uniquify_form Expr =
| Src = Expr.meta_
| R = let GSrc (if got Src then Src else GSrc)
  | case Expr
    [_fn As @Body]
      | Bs = if As.is_text then [As] else As
      | BadArg = Bs.find{?.is_text^not}
      | when got BadArg: compiler_error "invalid argument [BadArg]"
      | when Bs.size <> Bs.uniq.size: compiler_error "duplicate args in [Bs]"
      | Rs = Bs.map{[? ?.rand]}
      | let GUniquifyStack [Rs @GUniquifyStack]
        | Bs = Rs.map{?.1}
        | Bs = if As.is_text then Bs.0 else Bs
        | [_fn Bs @Body.map{&uniquify_expr}]
    [_quote X] | when X.is_text: GHoistedTexts.X <= @rand 'T'
               | Expr
    [_label X] Expr
    [_goto X] Expr
    [_call @Xs] Xs^uniquify_form
    Xs | Xs <= uniquify_let Xs
       | Xs.map{&uniquify_expr}
| when got Src: R <= meta R Src
| R

uniquify_name S = for Closure GUniquifyStack: for X Closure: when X.0 >< S: leave X.1

uniquify_atom Expr =
| less Expr.is_text: leave Expr
| when Expr.size and Expr.0 >< _: leave Expr
| Renamed = uniquify_name Expr
| when no Renamed: compiler_error "undefined variable `[Expr]`"
| Renamed

uniquify_expr Expr = if Expr.is_list
                     then uniquify_form Expr
                     else uniquify_atom Expr

uniquify Expr = //gives each variables unique name
| let GUniquifyStack []
  | R = uniquify_expr Expr
  | [[_fn (map [K V] GHoistedTexts V) R] @(map [K V] GHoistedTexts [_text K])]

ssa_list K Xs =
| less Xs.size: leave: ssa move K 'Empty'
| L = ssa_var l
| ssa arl L Xs.size
| for [I X] Xs.i: ssa starg L I X^ev
| ssa tagged K L \T_LIST

ssa_data K Type Xs =
| Size = Xs.size
| TypeName = Type.1
| TypeVar = resolve_type TypeName
| when no GTypeParams.TypeName:
  | GTypeParams.TypeName <= 1
  | ssaI set_type_params TypeVar Size Type.1^ssa_text
| ssa alloc_data K TypeVar Size
| for [I X] Xs.i: ssa dinit K I X^ev

ssa_subtype K Super Sub =
| ssa subtype Super.1^resolve_type Sub.1^resolve_type
| ssa move K 0

ssa_dget K Src Off =
| less Off.is_int: compiler_error "dget: offset must be integer"
| ssa dget K Src^ev Off

ssa_dset K Dst Off Value =
| less Off.is_int: compiler_error "dset: offset must be integer"
| D = ev Dst
| V = ssa_var r
| ssa_expr V Value
| ssa dset D Off V
| ssa move K V

ssa_dmet K MethodName TypeName Handler =
| MethodVar = MethodName.1^resolve_method
| TypeVar = resolve_type TypeName.1
| ssa dmet MethodVar TypeVar Handler^ev
| ssa move K 0

ssa_label Name = ssa local Name

ssa_goto Name =
| N = GBases.locate{B => got B.locate{?><Name}}
| when no N: compiler_error "cant find label [Name]"
| times I N
  | ssa gc (ssa_var d) 0 // FIXME: have to GC, since base-pop wont LIFT
  | ssa bpop
| ssa jmp Name

ssa_mark Name = GFnMeta.GCurProperFn.name <= Name

ssa_fixed1 K Op X = ssa Op K X^ev
ssa_fixed2 K Op A B = ssa Op K A^ev B^ev

ssa_alloc K N =
| X = ssa_var x
| ssa_fixed1 X unfxn N
| ssa arl K X

ssa_store Base Off Value = ssa utstor Base^ev Off^ev Value^ev
ssa_tagged K Tag X = ssa tagged K X^ev Tag.1

ssa_text String =
| It = GTextsMap.String
| when got It: leave It
| push String^ssa_cstring GTexts
| as Tx "tx\[[GTextsCount++]\]": GTextsMap.String <= Tx

ssa_ffi_var Type Name =
| V = @rand v
| ssa ffi_var Type V
| V

ssa_ffi_call K Type F As =
| F <= ev F
| As <= map A As: ev A
| Type <= map X Type.tail
          | case X.1
            text | 'text_'
            ptr | 'voidp_'
            T | T
| [ResultType @AsTypes] = Type
| less As.size >< AsTypes.size: compiler_error "argument number doesn't match signature"
| R = less ResultType >< void: ssa_ffi_var ResultType r
| ATs = AsTypes
| Vs = map A As | AType = pop ATs
                | V = ssa_ffi_var AType v
                | ssa "ffi_to_[AType]" V A
                | V
| ssa ffi_call ResultType R F AsTypes Vs
| if ResultType >< void then ssa move K 0 else ssa "ffi_from_[ResultType]" K R

ssa_form K Xs =
| Src = Xs.meta_
| let GSrc (if got Src then Src else GSrc): case Xs
  [_fn As Body] | ssa_fn K As Body Xs
  [_if Cnd Then Else] | ssa_if K Cnd Then Else
  [_quote X @Xs] | ssa_quote K X
  [_set Place Value] | ssa_set K Place Value
  [_progn @Xs] | ssa_progn K Xs
  [_label Name] | ssa_label Name
  [_goto Name] | ssa_goto Name
  [_mark Name] | ssa_mark Name.1
  [_data Type @Xs] | ssa_data K Type Xs
  [_subtype Super Sub] | ssa_subtype K Super Sub
  [_dget Src Index] | ssa_dget K Src Index
  [_dset Dst Index Value] | ssa_dset K Dst Index Value
  [_dmet Method Type Handler] | ssa_dmet K Method Type Handler
  [_mcall O Method @As] | ssa_apply_method K Method O As
  [_list @Xs] | ssa_list K Xs
  [_text X] | ssa move K X^ssa_text
  [_alloc N] | ssa_alloc K N
  [_store Base Off Value] | ssa_store Base Off Value
  [_tagged Tag X] | ssa_tagged K Tag X
  [_import Lib Symbol] | ssa_import K Lib Symbol
  [_add A B] | ssa_fixed2 K fxnadd A B
  [_sub A B] | ssa_fixed2 K fxnsub A B
  [_eq A B] | ssa_fixed2 K fxneq A B
  [_lt A B] | ssa_fixed2 K fxnlt A B
  [_gte A B] | ssa_fixed2 K fxngte A B
  [_tag X] | ssa_fixed1 K fxntag X
  [_fatal Msg] | ssa fatal Msg^ev
  [_this_method] | ssa this_method K
  [_method_name Method] | ssa method_name K Method^ev
  [_method Name] | ssa move K: resolve_method Name.1
  [_type_id O] | ssa type_id K O^ev
  [_setjmp] | ssa setjmp K
  [_longjmp State Value] | ssa longjmp State^ev Value^ev
  [_set_unwind_handler H] | ssa set_unwind_handler K H^ev
  [_remove_unwind_handler] | ssa set_unwind_handler K
  [_ffi_call Type F @As] | ssa_ffi_call K Type F As
  [_ffi_get Type Ptr Off] | ssa ffi_get K Type.1 Ptr^ev Off^ev
  [_ffi_set Type Ptr Off Val] | ssa ffi_set Type.1 Ptr^ev Off^ev Val^ev
                              | ssa move K 0
  [F @As] | ssa_apply K F As
  [] | ssa_atom K No
  Else | compiler_error "special form: [Xs]"

ssa_atom K X =
| if X.is_int then
    | when X > #7FFFFFFF or X < -#7FFFFFFF: X <= "[X]LL" //FIXME: kludge
    | ssa ldfxn K X
  else if X.is_text then ssa_symbol K X No
  else if X >< No then ssa move K 'No'
  else if X.is_float then ssa load_float K X
  else compiler_error "bad atom: [X]"

ssa_expr K X = if X.is_list then ssa_form K X else ssa_atom K X

ssa_fnmeta_entry Fn Name Size NArgs Origin =
| OrigBytes = ssa_cstring "[Origin.2]"
| NameBytes = if Name then Name^ssa_cstring else 0
| [Size NArgs NameBytes Fn Origin.0 Origin.1 OrigBytes]

find_closes_meta Expr =
| if Expr.is_meta then Expr.meta_
  else if Expr.is_list then
   | for X Expr:
     | It = find_closes_meta X
     | when got It: leave It
   | No
  else No

peephole_optimize Xs =
| Vs = t size/2000
| Cs = t size/2000
| for X Xs: when X.is_list and X.size:
  if X.0><var then Vs.(X.1) <= 1
  else for A X.tail: when A.is_text and got Vs.A: Cs.A <= Cs.A^~{0}+1
| Ys = []
| till Xs.end:
  | X = pop Xs
  | case X
    [move dummy V] | pass
    [ldarg dummy Base Pos] | pass
    [var V]
      | case Xs
        [[move &V T] [starg A B &V] @Zs]
          | when Cs.V><2
            | push [starg A B T] Ys
            | Xs <= Zs
            | pass
  | push X Ys
| Ys.flip

produce_ssa Entry Expr =
| let GEnv []
      GOut []
      GFns []
      GFnMeta (t size/500)
      GInits []
      GBytes []
      GStrings (t size/500)
      GRTypes (t size/500)
      GRTypesCount 0
      GTypeParams (t size/500)
      GTexts []
      GTextsMap (t size/500)
      GTextsCount 0
      GMethods (t size/500)
      GMethodsCount 0
      GImportLibs (t)
      GImportLibsCount 0
      GImports (t size/500)
      GImportsCount 0
      GClosure []
      GBases [[]]
      GHoistedTexts (t size/1000)
  | ssa entry Entry
  | Origin = find_closes_meta Expr
  | less got Origin: Origin <= [-1 -1 unknown]
  | R = ssa_var result
  | Expr <= uniquify Expr
  | ssa_expr R Expr
  | ssa return R
  | ssa entry setup
  | Libs = map K,N GImportLibs [K^ssa_cstring N]
  | Libs = Libs.sort{?1<??1}{?0}
  | GFnMeta.setup <= fnmeta name/'<init>' size/0 nargs/0 origin/Origin
  | GFnMeta.entry <= fnmeta name/'<toplevel>' size/0 nargs/0 origin/Origin
  | Types = map Name,[Index SN CStr] GRTypes: Index,CStr
  | Types = Types.sort{?0 < ??0}{?1}
  | Meths = map Name,[Index SN CStr] GMethods: Index,CStr
  | Meths = Meths.sort{?0 < ??0}{?1}
  | Metas = map Fn,M GFnMeta: ssa_fnmeta_entry Fn M.name M.size M.nargs M.origin
  | Imps = map Name,[N R Key Lib Symbol] GImports: [N Lib Symbol]
  | Imps = Imps.sort{?0 < ??0}
  | Header = [header GBytes tbls fmtbl,Metas
              [tx,GTexts.flip ty,Types mt,Meths libs,Libs imlib,Imps{?1} im,Imps{?2}]]
  | ssa tables_init tbls
  | for X GInits.flip: push X GOut
  | ssa return_no_gc 0
  | Rs = [GOut@GFns].flip.join.flip
  | Rs <= peephole_optimize Rs
  | [Header @Rs]

GCompiled = No

c Statement = push Statement GCompiled
cnorm [X@Xs] = c "  [X.upcase]([(map X Xs "[X]").text{','}]);"

ctable Type Name Xs =
| Head = "static [Type] [Name]\[[Xs.size]\] = {\n"
| Xs = map X Xs: if X.is_text then X else "(void*)[X]"
| [Head Xs.text{',\n'} "};\n"].text

ssa_to_c_do_header Header =
| [HeaderId Bytes TotName [MetaName MetaEntries] Tables] = Header
| MetaXs = map [Size NArgs Name Fn Row Col Origin] MetaEntries:
  | " {[Size],(void*)FIXNUM([NArgs]),[Name],[Fn],[Row],[Col],[Origin]}"
| TableDecls = [ctable{'fn_meta_t' MetaName MetaXs}]
| ToT = [MetaXs.size,MetaName] //table of tables
| for [Name Xs] Tables:
  | push ctable{'void*' Name Xs} TableDecls
  | push Xs.size,Name ToT
| TotTable = map [Size TableName] ToT.flip: " {[Size],[TableName]}"
| ByteDelcs = []
| for Name,Xs Bytes
  | Brackets = '[]'
  | Values = (map X Xs X.as_text).text{','}
  | push "static uint8_t [Name][Brackets] = {[Values]};" ByteDelcs
| [@ByteDelcs @TableDecls.flip ctable{'tot_entry_t' TotName TotTable}]

ssa_to_c Xs = let GCompiled []
| Statics = []
| Decls = []
| Imports = t
| TableDecls = ssa_to_c_do_header: pop Xs
| c 'BEGIN_CODE'
| for X Xs: case X
  [entry Name] | c "ENTRY([Name])"
  [label Name] | push "DECL_LABEL([Name])" Decls
               | c "LABEL([Name])"
  [load_lib Dst LibCStr] | c "  LOAD_LIB([Dst],[LibCStr]);"
  [ffi_call ResultType Dst F ArgsTypes Args]
    | ArgsText = Args.text{', '}
    | ArgsTypesText = ArgsTypes.text{', '}
    | Call = "(([ResultType](*)([ArgsTypesText]))[F])([ArgsText]);"
    | when got Dst: Call <= "[Dst] = [Call]"
    | c "  [Call]"
  Else | cnorm X //FIXME: check if it is known and has correct argnum
| c 'END_CODE'
| GCompiled <=
   ['#include "symta.h"'
    @Decls.flip
    @TableDecls
    @GCompiled.flip]
| GCompiled.text{'\n'}

ssa_produce_file Src =
| Ssa = produce_ssa entry Src
| Text = ssa_to_c Ssa
| Text

export produce_ssa ssa_to_c ssa_produce_file
