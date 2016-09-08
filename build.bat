@echo off
set bs=bootstrap/c/
set rt=./runtime/
echo compiling symta.exe
call cr
mkdir lib
echo compiling core
call c %rt% %bs%core_.c -o lib/core_.
echo compiling reader
call c %rt% %bs%reader.c -o lib/reader.
echo compiling compiler
call c %rt% %bs%compiler.c -o lib/compiler.
echo compiling macro
call c %rt% %bs%macro.c -o lib/macro.
echo compiling eval
call c %rt% %bs%eval.c -o lib/eval.
echo compiling main
call c %rt% %bs%main.c -o lib/main.
