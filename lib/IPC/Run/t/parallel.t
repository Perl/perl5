#!/usr/bin/perl -w

=head1 NAME

parallel.t - Test suite for running multiple processes in parallel.

=cut

BEGIN { 
    if( $ENV{PERL_CORE} ) {
	use Cwd;
        $^X = Cwd::abs_path($^X);
	$^X = qq("$^X") if $^X =~ /\s/;
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
    }
}

## Handy to have when our output is intermingled with debugging output sent
## to the debugging fd.
$| = 1 ;
select STDERR ; $| = 1 ; select STDOUT ;

use strict ;

use Test ;

use IPC::Run qw( start pump finish ) ;
use UNIVERSAL qw( isa ) ;

sub Win32_MODE() ;
*Win32_MODE = \&IPC::Run::Win32_MODE ;

## Win32 does not support a lot of things that Unix does.  These
## skip_unless subs help that.
##
## TODO: There are also a few things that Win32 supports (passing Win32 OS
## handles) that we should test for, conversely.
sub skip_unless_subs(&) {
   if ( Win32_MODE ) {
      return sub {
         skip "Can't spawn subroutines on $^O", 0 ;
      } ;
   }
   shift ;
}

my $text1 = "Hello world 1\n" ;
my $text2 = "Hello world 2\n" ;

my @perl    = ( $^X ) ;

my @catter = ( @perl, '-pe1' ) ;

sub slurp($) {
   my ( $f ) = @_ ;
   open( S, "<$f" ) or return "$! $f" ;
   my $r = join( '', <S> ) ;
   close S ;
   return $r ;
}


sub spit($$) {
   my ( $f, $s ) = @_ ;
   open( S, ">$f" ) or die "$! $f" ;
   print S $s or die "$! $f" ;
   close S or die "$! $f" ;
}

my ( $h1, $h2 ) ;
my ( $out1, $out2 ) ;

my @tests = (

sub {
   $h1 = start \@catter, "<", \$text1, ">", \$out1 ;
   ok $h1 ;
},

sub {
   $h2 = start \@catter, "<", \$text2, ">", \$out2 ;
   ok $h2 ;
},

sub {
   pump $h1 ;
   ok 1 ;
},

sub {
   pump $h2 ;
   ok 1 ;
},

sub {
   finish $h1 ;
   ok 1 ;
},

sub {
   finish $h2 ;
   ok 1 ;
},

) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;
