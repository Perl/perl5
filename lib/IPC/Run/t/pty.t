#!/usr/bin/perl -w

=head1 NAME

pty.t - Test suite for IPC::Run's pty (psuedo-terminal) support

=head1 DESCRIPTION

This test suite starts off with a test that seems to cause a deadlock
on freebsd: \@cmd, '<pty<', ... '>', ..., '2>'... 

This seems to cause the child process entry in the process table to
hang around after the child exits.  Both output pipes are closed, but
the PID is still valid so IPC::Run::finish() thinks it's still alive and
the whole shebang deadlocks waiting for the child to exit.

This is a very rare corner condition, so I'm not patching in a fix yet.
One fix might be to hack IPC::Run to close the master pty when all outputs
from the child are closed.  That's a hack, not sure what to do about it.

This problem needs to be reproduced in a standalone script and investigated
further, but I have not the time.

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


use strict ;

use Test ;

use IPC::Run::Debug qw( _map_fds );
use IPC::Run qw( start pump finish ) ;
use UNIVERSAL qw( isa ) ;

select STDERR ; $| = 1 ; select STDOUT ;

sub pty_warn {
   warn "\nWARNING: $_[0].\nWARNING: '<pty<', '>pty>' $_[1] not work.\n\n";
}

if ( $^O !~ /Win32/ ) {
#   my $min = 0.9 ;
   for ( eval { require IO::Pty ; IO::Pty->VERSION } ) {
      s/_//g if defined ;
      if ( ! defined ) {
	 pty_warn "IO::Pty not found", "will" ;
      }
      elsif ( $_ == 0.02 ) {
	 pty_warn "IO::Pty v$_ has spurious warnings, try 0.9 or later", "may"
      }
      elsif ( $_ < 1.00 ) {
	 pty_warn "IO::Pty 1.00 is strongly recommended", "may" ;
      }
   }
}


my $echoer_script = <<TOHERE ;
\$| = 1 ;
\$s = select STDERR ; \$| = 1 ; select \$s ;
while (<>) {
   print STDERR uc \$_ ;
   print ;
   last if /quit/ ;
}
TOHERE

##
## $^X is the path to the perl binary.  This is used run all the subprocesses.
##
my @echoer = ( $^X, '-e', $echoer_script ) ;

my $in ;
my $out ;
my $err;

my $h ;
my $r ;

my $fd_map ;

my $text = "hello world\n" ;

## TODO: test lots of mixtures of pty's and pipes & files.  Use run().

## Older Perls can't ok( a, qr// ), so I manually do that here.
my $exp ;

my $platform_skip = $^O =~ /(?:aix|freebsd|openbsd)/ ? "$^O deadlocks on this test" : "" ;

my @tests = (
##
## stdin only
##
sub {
   return skip $platform_skip, 1 if $platform_skip;
   $out = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = _map_fds ;
   $h = start \@echoer, '<pty<', \$in, '>', \$out, '2>', \$err ;

   $in  = "hello\n" ;
   $? = 0 ;
   pump $h until $out =~ /hello/ && $err =~ /HELLO/ ;
   ok( $out, "hello\n" ) ;
},
sub {
   return skip $platform_skip, 1 if $platform_skip;
   $exp = qr/^HELLO\n(?!\n)$/ ;
   $err =~ $exp ? ok( 1 ) : ok( $err, $exp ) ;
},
sub {
   return skip $platform_skip, 1 if $platform_skip;
   ok( $in, '' )
},

sub {
   return skip $platform_skip, 1 if $platform_skip;
   $in  = "world\n" ;
   $? = 0 ;
   pump $h until $out =~ /world/ && $err =~ /WORLD/ ;
   ok( $out, "hello\nworld\n" ) ;
},
sub {
   return skip $platform_skip, 1 if $platform_skip;
   $exp = qr/^HELLO\nWORLD\n(?!\n)$/ ;
   $err =~ $exp ? ok( 1 ) : ok( $err, $exp ) ;
},
sub {
   return skip $platform_skip, 1 if $platform_skip;
   ok( $in, '' )
},

sub {
   return skip $platform_skip, 1 if $platform_skip;
   $in = "quit\n" ;
   ok( $h->finish ) ;
},
sub {
   return skip $platform_skip, 1 if $platform_skip;
   ok( ! $? )
},
sub {
   return skip $platform_skip, 1 if $platform_skip;
   ok( _map_fds, $fd_map )
},

##
## stdout, stderr
##
sub {
   $out = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = _map_fds ;
   $h = start \@echoer, \$in, '>pty>', \$out ;
   $in  = "hello\n" ;
   $? = 0 ;
   pump $h until $out =~ /hello/ ;
   ## We assume that the slave's write()s are atomic
   $exp = qr/^(?:hello\r?\n){2}(?!\n)$/i ;
   $out =~ $exp ? ok( 1 ) : ok( $out, $exp ) ;
},
sub { ok( $in, '' ) },

sub {
   $in  = "world\n" ;
   $? = 0 ;
   pump $h until $out =~ /world/ ;
   $exp = qr/^(?:hello\r?\n){2}(?:world\r?\n){2}(?!\n)$/i ;
   $out =~ $exp ? ok( 1 ) : ok( $out, $exp ) ;
},
sub { ok( $in, '' ) },

sub {
   $in = "quit\n" ;
   ok( $h->finish ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

##
## stdout only
##
sub {
   $out = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = _map_fds ;
   $h = start \@echoer, \$in, '>pty>', \$out, '2>', \$err ;
   $in  = "hello\n" ;
   $? = 0 ;
   pump $h until $out =~ /hello/ && $err =~ /HELLO/ ;
   $exp = qr/^hello\r?\n(?!\n)$/ ;
   $out =~ $exp ? ok( 1 ) : ok( $out, $exp ) ;
},
sub {
   $exp = qr/^HELLO\n(?!\n)$/ ;
   $err =~ $exp ? ok( 1 ) : ok( $err, $exp ) ;
},
sub { ok( $in, '' ) },

sub {
   $in  = "world\n" ;
   $? = 0 ;
   pump $h until $out =~ /world/ && $err =~ /WORLD/ ;
   $exp = qr/^hello\r?\nworld\r?\n(?!\n)$/ ;
   $out =~ $exp ? ok( 1 ) : ok( $out, $exp ) ;
},
sub {
   $exp = qr/^HELLO\nWORLD\n(?!\n)$/ ,
   $err =~ $exp ? ok( 1 ) : ok( $err, $exp ) ;
},
sub { ok( $in, '' ) },

sub {
   $in = "quit\n" ;
   ok( $h->finish ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },

##
## stdin, stdout, stderr
##
sub {
   $out = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = _map_fds ;
   $h = start \@echoer, '<pty<', \$in, '>pty>', \$out ;
   $in  = "hello\n" ;
   $? = 0 ;
   pump $h until $out =~ /hello.*hello.*hello/is ;
   ## We assume that the slave's write()s are atomic
   $exp = qr/^(?:hello\r?\n){3}(?!\n)$/i ;
   $out =~ $exp ? ok( 1 ) : ok( $out, $exp ) ;
},
sub { ok( $in, '' ) },

sub {
   $in  = "world\n" ;
   $? = 0 ;
   pump $h until $out =~ /world.*world.*world/is ;
   $exp = qr/^(?:hello\r?\n){3}(?:world\r?\n){3}(?!\n)$/i ;
   $out =~ $exp ? ok( 1 ) : ok( $out, $exp ) ;
},
sub { ok( $in, '' ) },

sub {
   $in = "quit\n" ;
   ok( $h->finish ) ;
},
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
) ;

plan tests => scalar @tests ;

unless ( eval { require IO::Pty ; } ) {
   skip( "skip: IO::Pty not found", 0 ) for @tests ;
   exit ;
}

print "# Using IO::Tty $IO::Tty::VERSION\n";
print "# Using IO::Pty $IO::Pty::VERSION\n";

$_->() for ( @tests ) ;
