@echo off
rem USE THIS SCRIPT TO RECOMPILE SYMTA.EXE
set PATH=C:\Program Files\mingw-w64\x86_64-6.2.0-win32-seh-rt_v5-rev0\mingw64\bin;%PATH%
set cflags=-O1 -Wno-return-type -Wno-pointer-sign -D WINDOWS -I ./runtime
set bs=bootstrap/c/
gcc %cflags% -I ./runtime/w runtime/runtime.c runtime/w/dlfcn.c runtime/w/compat.c -o symta.exe
