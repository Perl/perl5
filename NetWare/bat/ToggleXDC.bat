@echo off
@rem AUTHOR: sgp
@rem CREATED: 2nd November 1999
@rem LAST REVISED: 6th April 2001
@rem Batch file to toggle XDC flag setting, to link with XDC or not
@rem This file is called from MPKBuild.bat. 

if "%1" == "" goto Usage

if "%1" == "/now" goto now
if "%1" == "on" goto yes
if "%1" == "off" goto no
if "%1" == "/?" goto usage
goto dontknow

:now
if "%USE_XDC%" == "" echo USE_XDC is removed, doesn't link with XDCDATA
if not "%USE_XDC%"  == "" echo USE_XDC is set, links with XDCDATA, XDCFLAGS = %XDCFLAGS%
goto exit

:yes
Set USE_XDC=1
echo ....USE_XDC is set, links with XDCDATA
if "%2" == "" SET XDCFLAGS=-n
if not "%2" == "" SET XDCFLAGS=%2
if not "%3" == "" SET XDCFLAGS=%XDCFLAGS% %3
echo ....XDCFLAGS set to %XDCFLAGS%
goto exit

:no
Set USE_XDC=
SET XDCFLAGS=
echo ....USE_XDC is removed. doesn't link with XDCDATA
goto exit

:dontknow
goto Usage

:Usage
 @echo on
 @echo "Usage: ToggleXDC [on|off] [[flag1] [flag2]]"
 @echo "Usage: ToggleD2 /now"  - To display current setting
:exit
