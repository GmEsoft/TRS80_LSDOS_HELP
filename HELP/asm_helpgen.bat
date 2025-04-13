@echo off
set NAME=HELPGEN
set ZMAC=zmac\zmac

%ZMAC% -e %NAME%.ASM --od . --oo cmd,bds,lst
if errorlevel 1 pause && goto :eof
