@echo off
rem USE THIS SCRIPT TO COMPILE MODULE FILE
set wd=%~dp0
set T___T=%PATH%
set PATH=%wd%gcc\bin;%PATH%
set cflags=-O1 -nostdlib -s -fno-exceptions -Wno-return-type -Wno-pointer-sign -D WINDOWS -I %1%
rem gcc -Wl,--subsystem,windows
gcc %cflags% -fpic -shared %2 -o %3
set PATH=%T___T%
