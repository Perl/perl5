@echo off
@rem AUTHOR: sgp
@rem CREATED: 24th July 2000
@rem LAST REVISED: 6th April 2001
@rem Batch file to set the path to MPK SDK
@rem This file is called from SetNWBld.bat. 

if "%1" == "/now" goto now
if "%1" == "" goto Usage
if "%1" == "/?" goto usage
if "%1" == "/h" goto usage

SET MPKBASE=%1
echo MPKBASE set to %1

goto exit

:now
@echo MPKBASE=%MPKBASE%
goto exit

:Usage
 @echo on
 @echo "Usage: setmpksdk <path to MPK sdk>"
 @echo "Usage: setmpksdk /now" - To display current setting
 @echo Ex. setmpksdk p:\sw\mpk
:exit
