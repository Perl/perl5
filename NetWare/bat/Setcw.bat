@echo off
@rem AUTHOR: sgp
@rem CREATED: 24th July 2000
@rem LAST REVISED: 6th April 2001
@rem LAST REVISED: 6th Mayl 2002
@rem AUTHOR: apc
@rem Batch file to set the path to CodeWarrior directories
@rem This file is called from SetNWBld.bat. 

if "%1" == "/now" goto now
if "%1" == "" goto Usage
if "%1" == "/?" goto usage
if "%1" == "/h" goto usage


set CODEWAR=%1
call buildtype r
@echo Buildtype set to Release type
set MWCIncludes=%1\include
set MWLibraries=%1\lib
set MWLibraryFiles=%1\lib\nwpre.obj;p:\apps\script\sw\cw\lib\mwcrtld.lib
set PATH=%PATH%;p:\apps\script\sw\cw\bin;
goto exit

:now
@echo CODEWAR=%CODEWAR%
goto exit

:Usage
 @echo on
 @echo "Usage: setcw <path to CodeWarrior>"
 @echo "Usage: setcw /now" - To display current setting
 @echo Ex. setcw d:\CodeWar
:exit

