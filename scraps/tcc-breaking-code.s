GEnv = No
GOut = No
GCurFn = No
GCurProperFn = No
GFnMeta = No
GInits = No
GBytes = No
GStrings = No
GRTypes = No
GRTypesCount = No
GTypeParams = No
GImports = No
GImportsCount = No
GTexts = No
GTextsMap = No
GTextsCount = No
GMethods = No
GMethodsCount = No
GImportLibs = No
GImportLibsCount = No
GFns = No
GClosure = No
GBases = No
GHoistedTexts = No
GSrc = 1+2
GAll = 1+2

ev X = ssa_expr r X
ssa_fn_body Expr = ssa_expr No Expr
ssa_fn K Args Expr O = ssa_fn_body Expr

ssa_set K Place Value = ev Value

ssa_progn K Xs =
| when Xs.end: Xs <= []
| till Xs.end
  | X = pop Xs
  | ssa_expr dummy X

ssa_apply K F As =
| ev F
| map A As: ev A

f00 =
f01 =
f02 =
f03 =
f04 =
f05 =
f06 =
f07 =
f08 =
f09 =
f10 =
f11 =
f12 =
f13 =
f14 =
f15 =
f16 =
f17 =
f18 =
f19 =

haltxs @Xs = halt

ssa_form K Xs =
| Src = Xs.meta_
| let GSrc (if got Src then Src else GSrc): case Xs
  [_fn As Body] | ssa_fn K As Body Xs
  [_set Place Value] | ssa_set K Place Value
  [_progn] | ssa_progn r Xs
  [_x A B C D] | haltxs a 1+2 1+2 1+2 1+2
  [_x A B C] | halt
  [_x A B C] | haltxs a b c
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b 1+2 1+2 1+2
  [_x A B] | halt
  [_x A B] | halt
  [_x A B] | haltxs a b c
  [_x A B] | haltxs a b c
  [_x A B] | haltxs a b c
  [_x A B] | haltxs a b c d
  [_x A B] | haltxs a b c d
  [_x A B] | haltxs a b c d
  [_x A B] | haltxs a b c d
  [_x A B] | haltxs a 1+2 1+2
  [_x A B] | halt
  [_x A] | halt
  [_x A] | halt
  [_x A] | halt
  [_x A] | halt
  [_x A] | halt
  [_x A] | haltxs 1+2
  [_x A] | haltxs a b
  [_x A] | haltxs a b c
  [_x A] | haltxs a b c
  [_x A] | haltxs a b 1+2
  [_x A] | haltxs a 1+2
  [_x A] | haltxs a b 1+2
  [_x A] | haltxs a b 1+2+3
  [_x] | halt
  [_x] | halt
  [_x] | halt
  [_x] | halt
  [F @As] | ssa_apply K F As
  [] | 123
  Else | halt

ssa_expr K X =
| R = if X.is_list then ssa_form K X else
| R

ssa_fnmeta_entry Fn Name Size NArgs Origin =

produce_ssa2 Entry Expr =
| let GEnv []
      GOut []
      GFns []
      GFnMeta 1+2
      GInits []
      GBytes []
      GStrings 1+2
      GRTypes 1+2
      GRTypesCount 0
      GTypeParams 1+2
      GTexts []
      GTextsMap 1+2
      GTextsCount 0
      GMethods 1+2
      GMethodsCount 0
      GImportLibs 1+2
      GImportLibsCount 0
      GImports 1+2
      GImportsCount 0
      GClosure []
      GBases 123
      GHoistedTexts 1+2
  | Origin = [-1 -1 unknown]
  | ssa_expr r Expr
  | Types = map Name,[Index SN CStr] GRTypes: Index,CStr
  | Types = Types.sort{?0 < ??0}{?1}
  | Meths = map Name,[Index SN CStr] GMethods: Index,CStr
  | Meths = Meths.sort{?0 < ??0}{?1}
  | Metas = map Fn,M GFnMeta: ssa_fnmeta_entry Fn M.name M.size M.nargs M.origin
  | Imps = map Name,[N R Key Lib Symbol] GImports: [N Lib Symbol]
  | Imps = Imps.sort{?0 < ??0}
  | Header = [header GBytes tbls fmtbl,Metas
              [tx,GTexts.flip ty,Types mt,Meths imlib,Imps{?1} im,Imps{?2}]]
  | haltxs a b
  | for X GInits.flip: push X GOut
  | Rs = [GOut@GFns].flip.join.flip
  | haltxs Header Rs


/*Src = "
((_fn () (_fn ()
  ((_fn () ((_fn (f__8 g__9) (_progn (_progn ((_fn (A__10) (_progn (_progn ((_fn (B__11) (_progn (_progn ((_fn (C__12) (_progn (_progn ((_fn (D__13) (_progn (_progn ((_fn (F__14) (_progn (_progn ((_fn (G__15) (_progn (_progn ((_fn (H__16) (_progn (_progn ((_fn (I__17) (_progn (_progn ((_fn (J__18) (_progn (_progn ((_fn (K__19) (_progn (_progn ((_fn (L__20) (_progn (_progn (_set g__9 (_fn (Xs__23) (_progn (_progn ((_fn (R__25) (_progn (_progn (_progn ((_fn (Xs__2__26) (_progn (_progn (_progn ((_fn (N__5__27) (_progn (_progn ((_fn (I__3__28) (_progn (_progn (_progn 123)))) 0)))) 123))))) 123))))) 0)))))))) 11)))) 10)))) 9)))) 8)))) 7)))) 6)))) 5)))) 4)))) 3)))) 2)))) 1)))) No No))))))"*/

SExpr = \((_fn () (_fn () ((_fn () ((_fn (f__8 g__9) (_progn (_progn ((_fn (A__10) (_progn (_progn ((_fn (B__11) (_progn (_progn ((_fn (C__12) (_progn (_progn ((_fn (D__13) (_progn (_progn ((_fn (F__14) (_progn (_progn ((_fn (G__15) (_progn (_progn ((_fn (H__16) (_progn (_progn ((_fn (I__17) (_progn (_progn ((_fn (J__18) (_progn (_progn ((_fn (K__19) (_progn (_progn ((_fn (L__20) (_progn (_progn (_set g__9 (_fn (Xs__23) (_progn (_progn ((_fn (R__25) (_progn (_progn (_progn ((_fn (Xs__2__26) (_progn (_progn (_progn ((_fn (N__5__27) (_progn (_progn ((_fn (I__3__28) (_progn (_progn (_progn 123)))) 0)))) 123))))) 123))))) 0)))))))) 11)))) 10)))) 9)))) 8)))) 7)))) 6)))) 5)))) 4)))) 3)))) 2)))) 1)))) No No))))))

test =
| Expr = SExpr//Src.parse{src in}.0.0
| Text = produce_ssa2 entry Expr

test
