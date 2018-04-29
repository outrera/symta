//fast arithmetics for fixnum expressions

tofxn E =
| less E.is_list: leave E
| case E
  [`<=` A @Xs] | leave [`<=` A Xs^tofxn]
  [esc @Xs] | leave Xs
| E <= E{?^tofxn}
| case E
  [`+` A B]  | [_add A B]
  [`-` A B]  | [_sub A B]
  [`-` X]    | [_sub 0 X]
  [`*` A B]  | [_mul A B]
  [`/` A B]  | [_div A B]
  [`%` A B]  | [_rem A B]
  [`><` A B] | [_eq A B]
  [`><` A B] | [_ne A B]
  [`<` A B]  | [_lt A B]
  [`>` A B]  | [_gt A B]
  [`<<` A B] | [_lte A B]
  [`>>` A B] | [_gte A B]
  [`.` A B] | if B.is_text and B.0.is_upcase then [_ref A B]
              else E
  [`++` X]  | form: let_ ((~O X)) (`|` (`<=` (X) (_add ~O 1)) ~O)
  [`--` X]  | form: let_ ((~O X)) (`|` (`<=` (X) (_sub ~O 1)) ~O)
  [`+=` A B]  | [`<=` A [_add A B]]
  [`-=` A B]  | [`<=` A [_sub A B]]
  [`*=` A B]  | [`<=` A [_mul A B]]
  [`/=` A B]  | [`<=` A [_div A B]]
  [`%=` A B]  | [`<=` A [_rem A B]]
  Else | E


fxn E = tofxn E

export 'fxn'
