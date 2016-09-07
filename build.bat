@echo off
set PATH=C:\Program Files\mingw-w64\x86_64-6.2.0-win32-seh-rt_v5-rev0\mingw64\bin;%PATH%
set cflags=-O1 -Wno-return-type -Wno-pointer-sign -D WINDOWS -I ./runtime
set bs=bootstrap/c/
echo compiling symta.exe
gcc %cflags% -I ./runtime/w runtime/runtime.c runtime/w/dlfcn.c runtime/w/compat.c -o symta.exe
mkdir lib
echo compiling core
gcc %cflags% -fpic -shared %bs%core_.c -o lib/core_.
echo compiling reader
gcc %cflags% -fpic -shared %bs%reader.c -o lib/reader.
echo compiling compiler
gcc %cflags% -fpic -shared %bs%compiler.c -o lib/compiler.
echo compiling macro
gcc %cflags% -fpic -shared %bs%macro.c -o lib/macro.
echo compiling eval
gcc %cflags% -fpic -shared %bs%eval.c -o lib/eval.
echo compiling main
gcc %cflags% -fpic -shared %bs%main.c -o lib/main.
