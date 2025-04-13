@echo off
call vcvars32.bat
if errorlevel 1 pause && exit /B %ERRORLEVEL%
cl helpgen.c
if errorlevel 1 pause && exit /B %ERRORLEVEL%
