@echo off
rem USE THIS SCRIPT TO COMPILE MODULE FILE
set wd=%~dp0
set T___T=%PATH%
set PATH=%wd%tcc\win32;%PATH%
set cflags=-rdynamic -D WINDOWS -I %1%
tcc %cflags% -shared %2 -o %3%.
set PATH=%T___T%
