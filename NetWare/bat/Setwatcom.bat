@echo off
@rem AUTHOR: sgp
@rem CREATED: 24th July 2000
@rem LAST REVISED: 6th April 2001
@rem Batch file to set the path to Watcom directories
@rem This file is called from SetNWBld.bat. 

if "%1" == "/now" goto now
if "%1" == "" goto Usage
if "%1" == "/?" goto usage
if "%1" == "/h" goto usage

set WATCOM=%1
echo WATCOM set to %1

goto exit

:now
@echo WATCOM=%WATCOM%
goto exit

:Usage
 @echo on
 @echo "Usage: setwatcom <path to Watcom>"
 @echo "Usage: setwatcom /now" - To display current setting
 @echo Ex. setwatcom d:\Watcom
:exit

