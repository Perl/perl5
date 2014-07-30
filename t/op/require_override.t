#!perl
use strict;
use warnings;

BEGIN {
    chdir 't';
    require './test.pl';
}

plan(tests => 6);

my @warns;
local $SIG{__WARN__}= sub { push @warns, $_[0] };
my $error;

eval "require; 1" or $error = $@;
ok(1, "Check that eval 'require' does not segv");
ok(0 == @warns, "We expect the eval to die, without producing warnings");
like($error, qr/Missing or undefined argument to require/, "Make sure we got the error we expect");

@warns= ();
$error= undef;

*CORE::GLOBAL::require = *CORE::GLOBAL::require = sub { };
eval "require; 1" or $error = $@;
ok(1, "Check that eval 'require' on overloaded require does not segv");
ok(0 == @warns, "We expect the eval to die, without producing warnings");

# NOTE! The following test does NOT represent a commitment or promise that the following logic is
# the *right* thing to do. It may well not be. But this is how it works now, and we want to test it.
# IOW, do not use this test as the basis to argue that this is how it SHOULD work. Thanks, yves.
ok(!defined($error), "We do not expect the overloaded version of require to die from no arguments");



