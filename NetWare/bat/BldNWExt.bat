@echo off
@rem AUTHOR: sgp
@rem CREATED: Sat Apr 14 13:05:44 2001
@rem LAST REVISED: Sat Apr 14 2001
@rem Batch file to toggle b/n building and not building NetWare
@rem specific extns - cgi2perl & perl2ucs.

if "%1" == "" goto Usage

if "%1" == "/now" goto now
if "%1" == "on" goto yes
if "%1" == "off" goto no
if "%1" == "/?" goto usage
if "%1" == "/h" goto usage
goto dontknow

:now
if not "%NW_EXTNS%" == "yes" echo NW_EXTNS is removed, doesn't build NetWare specific extensions
if "%NW_EXTNS%"  == "yes" echo NW_EXTNS is set, builds NetWare specific extensions
goto exit

:yes
Set NW_EXTNS=yes
echo ....NW_EXTNS is set, builds NetWare specific extensions
goto exit

:no
Set NW_EXTNS=
echo ....NW_EXTNS is removed, doesn't build NetWare specific extensions
goto exit

:dontknow
goto Usage

:Usage
 @echo on
 @echo "Usage: BldNWExt [on|off]"
 @echo "Usage: BldNWExt /now" - To display current setting
:exit
