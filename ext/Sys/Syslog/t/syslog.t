#!/usr/bin/perl -T

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;
use Test::More;
use Config;

# check that the module is at least available
plan skip_all => "Sys::Syslog was not build" 
  unless $Config{'extensions'} =~ /\bSyslog\b/;

# we also need Socket
plan skip_all => "Socket was not build" 
  unless $Config{'extensions'} =~ /\bSocket\b/;

BEGIN {
    plan tests => 16;

    # ok, now loads them
    eval 'use Socket';
    use_ok('Sys::Syslog', ':DEFAULT', 'setlogsock');
}

# check that the documented functions are correctly provided
can_ok( 'Sys::Syslog' => qw(openlog syslog syslog setlogmask setlogsock closelog) );


# check the diagnostics
# setlogsock()
eval { setlogsock() };
like( $@, qr/^Invalid argument passed to setlogsock; must be 'stream', 'unix', 'tcp', 'udp' or 'inet'/, 
    "calling setlogsock() with no argument" );

# syslog()
eval { syslog() };
like( $@, qr/^syslog: expecting argument \$priority/, 
    "calling syslog() with no argument" );

my $test_string = "uid $< is testing Perl $] syslog(3) capabilities";
my $r = 0;

# try to test using a Unix socket
SKIP: {
    skip "can't connect to Unix socket: _PATH_LOG unavailable", 6
      unless -e Sys::Syslog::_PATH_LOG();

    # The only known $^O eq 'svr4' that needs this is NCR MP-RAS,
    # but assuming 'stream' in SVR4 is probably not that bad.
    my $sock_type = $^O =~ /^(solaris|irix|svr4|powerux)$/ ? 'stream' : 'unix';

    eval { setlogsock($sock_type) };
    is( $@, '', "setlogsock() called with '$sock_type'" );
    TODO: {
        local $TODO = "minor bug";
        ok( $r, "setlogsock() should return true but returned '$r'" );
    }

    SKIP: {
        $r = eval { openlog('perl', 'ndelay', 'local0') };
        skip "can't connect to syslog", 4 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "openlog()" );
        ok( $r, "openlog() should return true but returned '$r'" );

        $r = eval { syslog('info', "$test_string by connecting to a Unix socket") };
        is( $@, '', "syslog()" );
        ok( $r, "syslog() should return true but returned '$r'" );
    }
}

# try to test using a INET socket
SKIP: {
    skip "assuming syslog doesn't accept inet connections", 6 if 1;

    my $sock_type = 'inet';

    $r = eval { setlogsock('inet') };
    is( $@, '', "setlogsock() called with '$sock_type'" );
    ok( $r, "setlogsock() should return true but returned '$r'" );

    $r = eval { openlog('perl', 'ndelay', 'local0') };
    is( $@, '', "openlog()" );
    ok( $r, " -> should return true but returned '$r'" );

    $r = eval { syslog('info', "$test_string by connecting to a INET socket") };
    is( $@, '', "syslog()" );
    ok( $r, " -> should return true but returned '$r'" );
}

