use strict;
use warnings;
use B;

use Test::Stream;
use Test::MostlyLike;
use Test::More tests => 4;
use Test::Builder; # Not loaded by default in modern mode
my $orig = Test::Builder->can('done_testing');

use Test::Stream::Tester;

my $ran = 0;
no warnings 'redefine';
my $file = __FILE__;
my $line = __LINE__ + 1;
*Test::Builder::done_testing = sub { my $self = shift; $ran++; $self->$orig(@_) };
use warnings;

my @warnings;
$SIG{__WARN__} = sub { push @warnings => @_ };

events_are(
    intercept {
        ok(1, "pass");
        ok(0, "fail");

        done_testing;
    },
    check {
        event ok => { bool => 1 };
        event ok => { bool => 0 };
        event plan => { max => 2 };
        directive 'end';
    },
);

events_are(
    intercept {
        ok(1, "pass");
        ok(0, "fail");

        done_testing;
    },
    check {
        event ok => { bool => 1 };
        event ok => { bool => 0 };
        event plan => { max => 2 };
        directive 'end';
    },
);

is($ran, 2, "We ran our override both times");
mostly_like(
    \@warnings,
    [
        qr{The new sub is 'main::__ANON__' defined in \Q$file\E around line $line},
        undef,
    ],
    "Got the warning once"
);
