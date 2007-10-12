#!perl

BEGIN {
    if($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
    require Config;
    import Config;
    if ($Config{'extensions'} !~ /\bOpcode\b/) {
	print "1..0\n";
	exit 0;
    }
}

use strict;
use Test::More;
use Safe;
plan(tests => 2);

my $c = new Safe;

my $r = $c->reval(q!
    sub UNIVERSAL::isa { "pwned" }
    (bless[],"Foo")->isa("Foo");
!);

is( $r, "pwned", "isa overriden in compartment" );
is( (bless[],"Foo")->isa("Foo"), 1, "... but not outside" );
