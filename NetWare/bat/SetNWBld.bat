@echo off
@rem AUTHOR: sgp
@rem CREATED: Thu 18th Jan 2001 09:18:08
@rem LAST REVISED: 6th April 2001
@rem Batch file to set the path to NetWare SDK, Watcom directories & MPK SDK
@rem This file calls setnlmsdk.bat, setwatcom.bat & setmpksdk.bat

REM If no parameters are passed, display usage
if "%1" == "" goto Usage
if "%1" == "/?" goto Usage
if "%1" == "/h" goto Usage

REM Display the current settings
if "%1" == "/now" goto now

REM If na is passed, don't set that parameter
if "%1" == "na" goto skip_nlmsdk_msg
:setnwsdk
call setnlmsdk %1
goto skip_nlmsdk_nomsg

:skip_nlmsdk_msg
@echo Retaining NLMSDKBASE=%NLMSDKBASE%
:skip_nlmsdk_nomsg

if "%2" == "" goto exit
if "%2" == "na" goto skip_watcom_msg
:setwatcom
call setwatcom %2
goto skip_watcom_nomsg

:skip_watcom_msg
@echo Retaining WATCOM=%WATCOM%
:skip_watcom_nomsg

if "%3" == "" goto exit
if "%3" == "na" goto skip_mpksdk_msg
:setmpk
call setmpksdk %3
goto skip_mpksdk_nomsg

:skip_mpksdk_msg
@echo Retaining MPKBASE=%MPKBASE%
:skip_mpksdk_nomsg

goto exit

:now
@echo NLMSDKBASE=%NLMSDKBASE%
@echo WATCOM=%WATCOM%
@echo MPKBASE=%MPKBASE%
goto exit

goto exit
:Usage
 @echo on
 @echo "Usage: setnwbld <path to NetWare SDK> [<path to Watcom dir>] [<path to MPK SDK>]"
 @echo "Usage: setnwbld /now" - To display current setting
 @echo Pass na if you don't want to change a setting
 @echo Ex. setnwbld d:\ndk\nwsdk na p:\mpk
 @echo Ex. setnwbld d:\ndk\
:exit
