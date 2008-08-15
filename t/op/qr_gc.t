#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 2;

$TODO = "leaking since 32751";

my $destroyed;
{
    no warnings 'redefine';
    sub Regexp::DESTROY { $destroyed++ }
}

{
    my $rx = qr//;
}

is( $destroyed, 1, "destroyed regexp" );

undef $destroyed;

{
    my $var = bless {}, "Foo";
    my $rx = qr/(?{ $var })/;
}

is( $destroyed, 1, "destroyed regexp with closure capture" );

