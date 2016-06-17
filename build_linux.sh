# eval.s also needs a fix for "-ldl -lm" to run on linux
cflags="-O1 -Wno-return-type -Wno-pointer-sign -ldl -lm -I ./runtime"
bs="bootstrap/c/"
echo "compiling runtime"
gcc ${cflags} runtime/runtime.c -o symta
mkdir lib
echo "compiling core"
gcc ${cflags} -fpic -shared "${bs}core_.c" -o lib/core_
echo "compiling reader"
gcc ${cflags} -fpic -shared "${bs}reader.c" -o lib/reader
echo "compiling compiler"
gcc ${cflags} -fpic -shared "${bs}compiler.c" -o lib/compiler
echo "compiling macro"
gcc ${cflags} -fpic -shared "${bs}macro.c" -o lib/macro
echo "compiling eval"
gcc ${cflags} -fpic -shared "${bs}eval.c" -o lib/eval
echo "compiling main"
gcc ${cflags} -fpic -shared "${bs}main.c" -o lib/main

