#!/usr/bin/perl -w

=head1 NAME

kill_kill.t - Test suite IPC::Run->kill_kill

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

sub skip_unless_ignore_term(&) {
   if ( IPC::Run::Win32_MODE() ) {
      return sub {
         skip "$^O does not support ignoring the TERM signal", 0 ;
      } ;
   }
   shift ;
}

my @quiter = ( $^X, '-e', 'sleep while 1' ) ;
my @zombie00 = ( $^X, '-e', '$SIG{TERM}=sub{};$|=1;print "running\n";sleep while 1');

my @tests = (
sub {
   my $h = start \@quiter ;
   my $needed_kill = $h->kill_kill ; # grace => 2 ) ;
   ok ! $needed_kill ;
},

skip_unless_ignore_term {
   my $out ;
   my $h = start \@zombie00, \undef, \$out ;
   pump $h until $out =~ /running/ ;
   my $needed_kill = $h->kill_kill( grace => 1 ) ;
   ok $needed_kill ;
},

## not testing coredumps; some systems don't provide them. #'

) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;
