#!/usr/bin/perl -w

=head1 NAME

bogus.t - test bogus file cases.

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

use IPC::Run qw( start ) ;
use UNIVERSAL qw( isa ) ;

my $r ;

sub Win32_MODE() ;
*Win32_MODE = \&IPC::Run::Win32_MODE ;

## Win32 does not support a lot of things that Unix does.  These
## skip_unless subs help that.
##
## TODO: There are also a few things that Win32 supports (passing Win32 OS
## handles) that we should test for, conversely.
sub skip_unless_exec(&) {
   if ( Win32_MODE ) {
      return sub {
         skip "Can't really exec() $^O", 0 ;
      } ;
   }
   shift ;
}

my @tests = (
sub {
   ## Older Test.pm's don't grok qr// in $expected.
   my $expected = 'file not found' ;
   eval { start ["./bogus_really_bogus"] } ;
   my $got = $@ =~ $expected ? $expected : $@ || "" ;
   ok $got, $expected, "starting ./bogus_really_bogus" ;
},

skip_unless_exec {
   ## Older Test.pm's don't grok qr// in $expected.
   my $expected = 'exec failed' ;
   my $h = eval {
      start [$^X, "-e", 1], _simulate_exec_failure => 1 ;
   } ;
   my $got = $@ =~ $expected ? $expected : $@ || "" ;
   ok $got, $expected, "starting $^X with simulated_exec_failure => 1" ;
},

) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;
