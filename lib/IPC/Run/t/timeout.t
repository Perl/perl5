#!/usr/bin/perl -w

=head1 NAME

timeout.t - Test suite for IPC::Run timeouts

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


## Separate from run.t so run.t is not too slow.

use strict ;

use Test ;

use IPC::Run qw( harness timeout ) ;
use UNIVERSAL qw( isa ) ;

my $h ;
my $t ;
my $in ;
my $out ;
my $started ;

my @tests = (

sub {
   $h = harness( [ $^X ], \$in, \$out, $t = timeout( 1 ) ) ;
   ok( isa( $h, 'IPC::Run' ) ) ;
},
sub { ok( !! $t->is_reset   ) },
sub { ok( !  $t->is_running ) },
sub { ok( !  $t->is_expired ) },

sub {
   $started = time ;
   $h->start ;
   ok( 1 ) ;
},
sub { ok( !  $t->is_reset   ) },
sub { ok( !! $t->is_running ) },
sub { ok( !  $t->is_expired ) },

sub {
   $in = '' ;
   eval { $h->pump };
   # Older perls' Test.pms don't know what to do with qr//s
   $@ =~ /IPC::Run: timeout/ ? ok( 1 ) : ok( $@, qr/IPC::Run: timeout/ ) ;
},

sub {
   my $elapsed = time - $started ;
   $elapsed >= 1 ? ok( 1 ) : ok( $elapsed, ">= 1" ) ;
},

sub { ok( $t->interval, 1 ) },
sub { ok( !  $t->is_reset   ) },
sub { ok( !  $t->is_running ) },
sub { ok( !! $t->is_expired ) },

##
## Starting from an expired state
##
sub {
   $started = time ;
   $h->start ;
   ok( 1 ) ;
},
sub { ok( !  $t->is_reset   ) },
sub { ok( !! $t->is_running ) },
sub { ok( !  $t->is_expired ) },
sub {
   $in = '' ;
   eval { $h->pump };
   $@ =~ /IPC::Run: timeout/ ? ok( 1 ) : ok( $@, qr/IPC::Run: timeout/ ) ;
},
sub { ok( !  $t->is_reset   ) },
sub { ok( !  $t->is_running ) },
sub { ok( !! $t->is_expired ) },

sub {
   my $elapsed = time - $started ;
   $elapsed >= 1 ? ok( 1 ) : ok( $elapsed, ">= 1" ) ;
},

sub {
   $h = harness( [ $^X ], \$in, \$out, timeout( 1 ) ) ;
   $started = time ;
   $h->start ;
   $in = '' ;
   eval { $h->pump };
   $@ =~ /IPC::Run: timeout/ ? ok( 1 ) : ok( $@, qr/IPC::Run: timeout/ ) ;
},

sub {
   my $elapsed = time - $started ;
   $elapsed >= 1 ? ok( 1 ) : ok( $elapsed, ">= 1" ) ;
},

) ;



plan tests => scalar @tests ;

$_->() for ( @tests ) ;

