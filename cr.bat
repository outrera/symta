@echo off
rem USE THIS SCRIPT TO RECOMPILE SYMTA.EXE
set PATH=C:\Program Files\mingw-w64\x86_64-6.2.0-win32-seh-rt_v5-rev0\mingw64\bin;%PATH%
set cflags=-O2 -fno-stack-protector -fomit-frame-pointer -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-ident -Wno-return-type -Wno-pointer-sign -D WINDOWS -I ./runtime
set rtw=./runtime/w/
gcc %cflags% -I %rtw% ./runtime/runtime.c %rtw%dlfcn.c %rtw%mman.c %rtw%sigaction.c %rtw%compat.c -s -o symta.exe
