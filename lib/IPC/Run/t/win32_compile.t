#!/usr/bin/perl -w

=head1 NAME

win32_compile.t - See if IPC::Run::Win32Helper compiles, even on Unix

=cut

BEGIN { 
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
	use Cwd;
        $^X = Cwd::abs_path($^X);
	$^X = qq("$^X") if $^X =~ /\s/;
    }
}

use strict ;

use Test ;

BEGIN {
   unless ( eval "require 5.006" ) {
       ## NOTE: I'm working around this here because I don't want this
       ## test to fail on non-Win32 systems with older Perls.  Makefile.PL
       ## does the require 5.6.0 to protect folks on Windows.
       plan tests => 1;
       skip "perl5.00503's Socket.pm does not export IPPROTO_TCP", 1, 1;
       exit 0;
   }


   $INC{$_} = 1 for qw( Win32/Process.pm Win32API/File.pm ) ;

   package Win32API::File ;

   use vars qw( @ISA @EXPORT ) ;

   @ISA = qw( Exporter ) ;
   @EXPORT = qw(
      GetOsFHandle 
      OsFHandleOpen
      OsFHandleOpenFd
      FdGetOsFHandle
      SetHandleInformation
      SetFilePointer

      HANDLE_FLAG_INHERIT
      INVALID_HANDLE_VALUE

      createFile
      WriteFile
      ReadFile
      CloseHandle

      FILE_ATTRIBUTE_TEMPORARY
      FILE_FLAG_DELETE_ON_CLOSE
      FILE_FLAG_WRITE_THROUGH

      FILE_BEGIN
   ) ;

   eval "sub $_ { 1 }" for @EXPORT ;

   use Exporter ;

   package Win32::Process ;

   use vars qw( @ISA @EXPORT ) ;

   @ISA = qw( Exporter ) ;
   @EXPORT = qw(
      NORMAL_PRIORITY_CLASS
   ) ;

   eval "sub $_ {}" for @EXPORT ;

   use Exporter ;
}

sub Socket::IPPROTO_TCP() { undef }

package main ;

use IPC::Run::Win32Helper ;
use IPC::Run::Win32IO ;

plan tests => 1 ;

ok 1 ;

