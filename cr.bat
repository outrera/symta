@echo off
rem USE THIS SCRIPT TO RECOMPILE SYMTA.EXE
set PATH=C:\Program Files\mingw-w64\x86_64-6.3.0-posix-seh-rt_v5-rev2\mingw64\bin;%PATH%
rem set PATH=C:\Users\nikita\Documents\tools\x86_64-6.2.0-release-win32-seh-rt_v5-rev1\mingw64\bin;%PATH%
set cflags= -O2 -fno-stack-protector -fomit-frame-pointer -fno-exceptions -fno-unwind-tables -fno-ident -Wno-return-type -Wno-pointer-sign -D WINDOWS -I ./runtime
rem -fno-asynchronous-unwind-tables -nostartfiles -e run 
set rtw=./runtime/w/
gcc %cflags% -I %rtw% ./runtime/runtime.c %rtw%ctx.c %rtw%dlfcn.c %rtw%mman.c %rtw%compat.c -s -o symta.exe
