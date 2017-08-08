//`case` matchers generating huge amount of C code,
//including around 4500 8-byte variables on stack, per function call
//GCC somehow optimizes it, but TCC is unable to optimize,
//resulting in stack overflow after a few hundred recursive calls.
//For now compiling runtime with "-Wl,--stack,10485760" solves the problem.

ssa_apply K F As =
| ssa_expr F
| for A As: ssa_expr A

haltxs @Xs = halt

ssa_expr Xs =
| case Xs
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [_x A B C] | haltxs a b c d
  [F @As] | ssa_apply r F As
  [] | 123
  Else | 123

gen N = if N>0 then [f (gen N-1)] else 123

Expr = gen 37

ssa_expr Expr
halt
