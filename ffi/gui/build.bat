@echo off
set PATH=C:\Program Files\mingw-w64\x86_64-6.3.0-posix-seh-rt_v5-rev2\mingw64\bin;%PATH%
set cflags2= -fno-stack-protector -fomit-frame-pointer -fno-exceptions -fno-unwind-tables -fno-ident -Wno-return-type -Wno-pointer-sign
rem -fpic
set cflags= -O2 -D WINDOWS -I ./include -I ../gfx/src/ -I ./deps/SDL2-2.0.2/x86_64-w64-mingw32/include/SDL2 -I ./deps/SDL2_mixer-2.0.2/x86_64-w64-mingw32/include/SDL2 -L ./deps/SDL2-2.0.2/x86_64-w64-mingw32/lib -L ./deps/SDL2_mixer-2.0.2/x86_64-w64-mingw32/lib
gcc %cflags% %cflags2% -shared ./src/main.c -lSDL2 -lSDL2_mixer -o main. && copy .\main ..\..\lib\ffi\gui\main
