#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::PerlRun 'perlrun';

use XS::APItest;

my ($stdout, $stderr, $status) = perlrun(<<'PROG');
use XS::APItest;
print "ok\n";
my_exit(1);
print "not\n";
PROG

is($stdout, "ok\n");
is($stderr, '');

# C's EXIT_FAILURE ends up as SS$_ABORT (decimal 44) on VMS, which gets
# shifted to 4.  Perl_my_exit (unlike Perl_my_failure_exit) does not 
# have access to the vmsish pragmas to modify that behavior.
 
my $exit_failure = $^O eq 'VMS' ? 4 : 1;
is($status, $exit_failure, "exit code plain my_exit");

($stdout, $stderr, $status) = perlrun(<<'PROG');
use XS::APItest;
print "ok\n";
call_sv( sub { my_exit(1); }, G_EVAL );
print "not\n";
PROG

is($stdout, "ok\n");
is($stderr, '');
is($status, $exit_failure, "exit code my_exit inside a call_sv with G_EVAL");

