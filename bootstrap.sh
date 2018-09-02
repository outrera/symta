bs=bootstrap/
rt="./runtime/"
echo compiling symta runtime
bash cr.osx
mkdir lib
echo compiling core
./c "$rt" "${bs}core_.c" lib/core_
echo compiling reader
./c "$rt" "${bs}reader.c" lib/reader
echo compiling compiler
./c "$rt" "${bs}compiler.c" lib/compiler
echo compiling macro
./c "$rt" "${bs}macro.c" lib/macro
echo compiling eval
./c "$rt" "${bs}eval.c" lib/eval
echo compiling main
./c "$rt" "${bs}main.c" lib/main
