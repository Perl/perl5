@rem = '--*-Perl-*--
@echo off
if (%PERL_CORE%)==() set PERL_CORE=perl
if not exist %PERL_CORE% set PERL_CORE=perl
if "%OS%" == "Windows_NT" goto WinNT
%PERL_CORE% -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
%PERL_CORE% -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl
#line 15

print $_, $/ for @ARGV;

__END__
:endofperl
