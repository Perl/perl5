#!/usr/bin/perl -w

=head1 NAME

signal.t - Test suite IPC::Run->signal

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

use IPC::Run qw( :filters :filter_imp start run filter_tests ) ;
use UNIVERSAL qw( isa ) ;

sub Win32_MODE() ;
*Win32_MODE = \&IPC::Run::Win32_MODE ;

## Win32 does not support a lot of things that Unix does.  These
## skip_unless subs help that.
##
## TODO: There are also a few things that Win32 supports (passing Win32 OS
## handles) that we should test for, conversely.
sub skip_unless_signals(&) {
   if ( Win32_MODE ) {
      return sub {
         skip "$^O does not support signals", 0 ;
      } ;
   }
   shift ;
}

use IPC::Run qw( start ) ;

my @receiver = (
   $^X,
   '-e',
   <<'END_RECEIVER',
      my $which = "          " ;
      sub s{ $which = $_[0] } ;
      $SIG{$_}=\&s for (qw(USR1 USR2));
      $| = 1 ;
      print "Ok\n";
      for (1..10) { sleep 1 ; print $which, "\n" }
END_RECEIVER
) ;

my $h ;
my $out ;

my @tests = (
skip_unless_signals {
   $h = start \@receiver, \undef, \$out ;
   pump $h until $out =~ /Ok/ ;
   ok 1 ;
},
skip_unless_signals {
   $out = "" ;
   $h->signal( "USR2" ) ;
   pump $h ;
   $h->signal( "USR1" ) ;
   pump $h ;
   $h->signal( "USR2" ) ;
   pump $h ;
   $h->signal( "USR1" ) ;
   pump $h ;
   ok $out, "USR2\nUSR1\nUSR2\nUSR1\n" ;
},

skip_unless_signals {
   $h->signal( "TERM" ) ;
   finish $h ;
   ok( 1 ) ;
},

) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;
