@echo off
@rem AUTHOR: apc
@rem CREATED: Thu 18th Jan 2001 09:18:08
@rem LAST REVISED: 6th April 2001
@rem LAST REVISED: 6th May 2002
@rem Batch file to set the path to Default Buildtype,NetWare SDK, CodeWarrior directories & MPK SDK and MPKbuild options
@rem This file calls buildtype with release as defualt,setnlmsdk.bat, setcw.bat & setmpksdk.bat and MpkBuild with off as default

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
if "%2" == "" goto err_exit
if "%2" == "na" goto skip_cw_msg
:setcw
call setcw %2
goto skip_cw_nomsg

:skip_cw_msg
@echo Retaining CODEWAR=%CODEWAR%
:skip_cw_nomsg

if "%3" == "" goto exit
if "%3" == "na" goto skip_mpksdk_msg

:setmpk
call setmpksdk %3
goto exit

:mpksdk_off
call mpkbuild off
@echo mpkbuild off
goto exit

:skip_mpksdk_msg
@echo Retaining MPKBASE=%MPKBASE%
goto exit

:now
@echo NLMSDKBASE=%NLMSDKBASE%
@echo cw=%cw%
@echo MPKBASE=%MPKBASE%
goto exit

goto exit

:err_exit
@echo Not Enough Parameters
goto Usage

:Usage
 @echo on
 @echo "Usage: setnwbld <path to NetWare SDK> [<path to CodeWarrior dir>] "
 @echo "Usage: setnwbld /now" - To display current setting
 @echo Pass na if you don't want to change a setting
 @echo Ex. setnwbld d:\ndk\nwsdk na 
 @echo Ex. setnwbld d:\ndk\
:exit
