@echo off
set bs=bootstrap/
set rt=./runtime/
echo compiling symta.exe
call cr
mkdir lib
echo compiling core
call c %rt% %bs%core_.c lib/core_.
echo compiling reader
call c %rt% %bs%reader.c lib/reader.
echo compiling compiler
call c %rt% %bs%compiler.c lib/compiler.
echo compiling macro
call c %rt% %bs%macro.c lib/macro.
echo compiling eval
call c %rt% %bs%eval.c lib/eval.
echo compiling main
call c %rt% %bs%main.c lib/main.
