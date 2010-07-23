#!perl -w

BEGIN {
    push @INC, "::lib:$MacPerl::Architecture:" if $^O eq 'MacOS';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bXS\/APItest\b/) {
	# Look, I'm using this fully-qualified variable more than once!
	my $arch = $MacPerl::Architecture;
        print "1..0 # Skip: XS::APItest was not built\n";
        exit 0;
    }
}

use strict;
use warnings;

BEGIN {
    require '../../t/test.pl';
    plan(6);
    use_ok('XS::APItest')
};

my $record = XS::APItest::peep_record;

XS::APItest::peep_enable;

# our peep got called and remembered the string constant
eval q[my $foo = q/affe/];
is(scalar @{ $record }, 1);
is($record->[0], 'affe');

XS::APItest::peep_record_clear;

# peep got called for each root op of the branch
$::moo = $::moo = 0;
eval q[my $foo = $::moo ? q/x/ : q/y/];
is(scalar @{ $record }, 2);
is($record->[0], 'x');
is($record->[1], 'y');
