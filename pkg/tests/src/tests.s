/*
Ys = [4 5 6]
yoba =
| Xs = [1 2 3]
| times I 100000000: Ys.1 <= Xs
| Ys
yoba
*/

/*Ys = [4 5 6]
yoba =
| Xs = [1 2 3]
| times I 100000000: Ys <= Xs
| Ys
yoba*/

/*
rle Xs =
| Ys = []
| while 1: case Xs [Z N%&Z @Zs] | [[N.size+1 Z] @!Ys]; Xs <= Zs
                   [Z @Zs] | [Z @!Ys]; Xs <= Zs
                   [] | leave Ys.flip

*/

tsay Msg =
| say "  [Msg]"

failed = bad "  test failed"

test_int =
| say 'testing int...'
| A = 123
| B = 456

| tsay "[A]^typename >< int and [B]^typename >< int"
| less A^typename >< int and B^typename >< int: failed

| tsay "A >< A"
| less A >< A: failed

| tsay "A <> B"
| less A <> B:failed

| tsay "A << A"
| less A << A: failed

| tsay "A << B"
| less A << B: failed

| tsay "A >> A"
| less A >> A: failed

| tsay "B >> A"
| less B >> A: failed

| tsay "B > A"
| less B > A: failed

| tsay "A < B"
| less A < B: failed

| tsay "A+B >< 579"
| less A+B >< 579: failed

| tsay "A+B >< -333"
| less A-B >< -333: failed

| tsay "A*B >< 56088"
| less A*B >< 56088: failed

| tsay "A*B/A >< B"
| less A*B/A >< B: failed

| tsay "'x'.code.char >< 'x'"
| less 'x'.code.char >< x: failed

| tsay "B^^A >< 72"
| less B^^A >< 72: failed
| 1

test_list =
| say 'testing list...'
| Ys = No
| Validate = (Xs => Xs.0 >< 1 and Xs.1 >< 2 and Xs.2 >< 3)

| tsay '[1 2 3]^typename >< list'
| less [1 2 3]^typename >< list: failed

| tsay '[456 1 2 3].tail'
| Ys <= [456 1 2 3].tail
| less Validate Ys: failed

| tsay '[@[1 2] 3]'
| Ys <= [@[1 2] 3]
| less Validate Ys: failed

| tsay '[1 @[2 3]]'
| Ys <= [1 @[2 3]]
| less Validate Ys: failed

| tsay '[1 @[2] 3]]'
| Ys <= [1 @[2] 3]
| less Validate Ys: failed

| tsay '(A B C => [A B C]) 1 2 3'
| Ys <= (A B C => [A B C]) 1 2 3
| less Validate Ys: failed

| tsay '(X@Xs => [@Xs X]) 3 1 2'
| Ys <= (X@Xs => [@Xs X]) 3 1 2
| less Validate Ys: failed

| tsay 'case [x [y 4] 2 [1 3] z] [x [y 4] B [A C] z] [A B C]'
| Ys <= case [x [y 4] 2 [1 3] z] [x [y 4] B [A C] z] [A B C]
| less Validate Ys: failed

| tsay '(Xs => (Xs.1 <= [1 2 3]; 0)) Xs'
| Xs = [a b c]
| (Xs => (Xs.1 <= [1 2 3]; 0)) Xs
| Ys <= Xs.1
| less Validate Ys: failed

| tsay '[2 2 3 1]^([C @(Xs<(&C).size) @Ys] => [@Ys @Xs])'
| Ys <= [2 2 3 1]^([C @(Xs<(&C).size) @Ys] => [@Ys @Xs])
| less Validate Ys: failed

| tsay '[1 2 3]+[1 2 3]-[1 2 3]'
| Ys <= [1 2 3]+[1 2 3]-[1 2 3]
| less Validate Ys: failed

| tsay '[1 2 3]*2/2'
| Ys <= [1 2 3]*2/2
| less Validate Ys: failed

| tsay '[3 1 2].sort{A B => A < B}'
| Ys = [3 1 2].sort{A B => A < B}
| less Validate Ys: failed
| 1

type object{X Y Z} x/X y/Y z/Z
object.sum = $x + $y + $z

type super
super.method = 'Super'
type sub.super
sub.method = 'Sub'

test_oop =
| say 'testing OOP...'
| O = object 1 2 3
| tsay 'O.is_object'
| less O.is_object: failed
| tsay 'O.sum >< 1+2+3'
| less O.sum >< 1+2+3: failed
| tsay 'O.x >< 1 and O.y >< 2 and O.z >< 3'
| less O.x >< 1 and O.y >< 2 and O.z >< 3: failed
| tsay "super{}.method >< 'Super'"
| less super{}.method >< 'Super': failed
| tsay "sub{}.method >< 'Sub'"
| less sub{}.method >< 'Sub': failed
| T = t{def(456) abc(123)}
| tsay "T.'abc'+T.'def' >< 456+123"
| less T.'abc'+T.'def' >< 456+123: failed
| tsay "T.abc+T.def >< 456+123"
| less T.abc+T.def >< 456+123: failed
| 1

run_tests =
| test_int
| test_list
| test_oop

export run_tests
