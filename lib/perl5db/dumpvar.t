#!./perl -- -*- mode: cperl; cperl-indent-level: 4 -*-

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;

$|=1;

my @prgs;
{
    local $/;
    @prgs = split "########\n", <DATA>;
    close DATA;
}

use Test::More;

plan tests => scalar @prgs;

require "dumpvar.pl";

sub unctrl    { print dumpvar::unctrl($_[0]), "\n" }
sub uniescape { print dumpvar::uniescape($_[0]), "\n" }
sub stringify { print dumpvar::stringify($_[0]), "\n" }

package Foo;

sub new { my $class = shift; bless [ @_ ], $class }

package Bar;

sub new { my $class = shift; bless [ @_ ], $class }

use overload '""' => sub { "Bar<@{$_[0]}>" };

package main;

my $foo = Foo->new(1..5);
my $bar = Bar->new(1..5);

for (@prgs) {
    my($prog, $expected) = split(/\nEXPECT\n?/, $_);
    # TODO: dumpvar::stringify() is controlled by a pile of package
    # dumpvar variables: $printUndef, $unctrl, $quoteHighBit, $bareStringify,
    # and so forth.  We need to test with various settings of those.
    my $out = tie *STDOUT, 'TieOut';
    eval $prog;
    my $ERR = $@;
    untie $out;
    if ($ERR) {
        ok(0, "$prog - $ERR");
    } else {
	if ($expected =~ m:^/:) {
	    like($$out, $expected, $prog);
	} else {
	    is($$out, $expected, $prog);
	}
    }
}

package TieOut;

sub TIEHANDLE {
    bless( \(my $self), $_[0] );
}

sub PRINT {
    my $self = shift;
    $$self .= join('', @_);
}

sub read {
    my $self = shift;
    substr( $$self, 0, length($$self), '' );
}

__END__
unctrl("A");
EXPECT
A
########
unctrl("\cA");
EXPECT
^A
########
uniescape("A");
EXPECT
A
########
uniescape("\x{100}");
EXPECT
\x{0100}
########
stringify(undef);
EXPECT
undef
########
stringify("foo");
EXPECT
'foo'
########
stringify("\cA");
EXPECT
"\cA"
########
stringify(*a);
EXPECT
*main::a
########
stringify(\undef);
EXPECT
/^'SCALAR\(0x[0-9a-f]+\)'$/i
########
stringify([]);
EXPECT
/^'ARRAY\(0x[0-9a-f]+\)'$/i
########
stringify({});
EXPECT
/^'HASH\(0x[0-9a-f]+\)'$/i
########
stringify(sub{});
EXPECT
/^'CODE\(0x[0-9a-f]+\)'$/i
########
stringify(\*a);
EXPECT
/^'GLOB\(0x[0-9a-f]+\)'$/i
########
stringify($foo);
EXPECT
/^'Foo=ARRAY\(0x[0-9a-f]+\)'$/i
########
stringify($bar);
EXPECT
/^'Bar=ARRAY\(0x[0-9a-f]+\)'$/i
########
dumpValue(undef);
EXPECT
undef
########
dumpValue(1);
EXPECT
1
########
dumpValue("\cA");
EXPECT
"\cA"
########
dumpValue("\x{100}");
EXPECT
'\x{0100}'
########
dumpValue("1\n2\n3");
EXPECT
'1
2
3'
########
dumpValue([1..3],1);
EXPECT
0  1
1  2
2  3
########
dumpValue({1..4},1);
EXPECT
1 => 2
3 => 4
########
dumpValue($foo,1);
EXPECT
0  1
1  2
2  3
3  4
4  5
########
dumpValue($bar,1);
EXPECT
0  1
1  2
2  3
3  4
4  5
########
