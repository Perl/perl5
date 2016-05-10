use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::API qw/intercept/;

plan 4;

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    require Test::Builder;
};

is(@warnings, 3, "got 3 warnings");

like(
    $warnings[0],
    qr/Test::Builder was loaded after Test2 initialization, this is not recommended/,
    "Warn about late Test::Builder load"
);

like(
    $warnings[1],
    qr/Formatter Test::Builder::Formatter loaded too late to be used as the global formatter/,
    "Got the formatter warning"
);

like(
    $warnings[2],
    qr/The current formatter does not support 'no_header'/,
    "Formatter does not support no_header",
);


