@echo off
@rem AUTHOR: sgp
@rem CREATED: 22nd May 2000
@rem LAST REVISED: 6th April 2001
@rem Batch file to set MPK/Non-MPK builds and toggle XDC flag setting
@rem This file calls ToggleXDC.bat

if "%1" == "" goto Usage

if "%1" == "/now" goto now
if "%1" == "on" goto yes
if "%1" == "off" goto no
if "%1" == "/?" goto usage
goto dontknow

:now
if "%USE_MPK%" == "" echo USE_MPK is removed, doesn't use MPK APIs
if not "%USE_MPK%"  == "" echo USE_MPK is set, uses MPK APIs, MPKBASE set to %MPKBASE%
call ToggleXDC %1
goto exit

:yes
Set USE_MPK=1
echo ....USE_MPK is set, uses MPK APIs
if "%2" == "" goto setdef
if "%2" == "default" goto setdef
SET MPKBASE=%2
:yescon1
call ToggleXDC on %3 %4
echo ....MPKBASE set to %MPKBASE%
goto exit

:no
Set USE_MPK=
SET MPKBASE=
if not "%2" == "" goto xdc_u
call ToggleXDC off
:nocon1
echo ....USE_MPK is removed. doesn't use MPK APIs
goto exit

:dontknow
goto Usage

:setdef
SET MPKBASE=p:\apps\mpk
goto yescon1

:xdc_u
call ToggleXDC on %2 %3
goto nocon1

:Usage
 @echo on
 @echo "Usage: MPKBuild [on][off] [[path][default]] [[flag1] [flag2]]"
 @echo "Usage: MPKBuild /now"  - To display current setting
 @echo Scenarios...
 @echo ...Use MPK, path set to default and XDC set to -u     :MPKBuild on
 @echo ...Use MPK, path set to default and XDC set to -u     :MPKBuild on default -n
 @echo ...Use MPK, path set to "path" and XDC set to -n      :MPKBuild on "path" -n
 @echo ...Use MPK, path set to default and XDC set to -n, -u :MPKBuild on default -n -u
 @echo ...No MPK, No XDC                                     :MPKBuild off
 @echo ...No MPK, Use XDC with -u flag                       :MPKBuild off -u
:exit
