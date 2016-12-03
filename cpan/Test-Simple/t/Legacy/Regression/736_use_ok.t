use warnings;
use strict;
use Test::More;

BEGIN {
    $INC{'MyWarner.pm'} = 1;
    package MyWarner;

    sub import {
        warnings::warnif('deprecated', "Deprected! run for your lives!");
    }
}

sub capture(&) {
    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift };
    $_[0]->();
    return $warn || "";
}

my $file = __FILE__;
my $line = __LINE__ + 2;
like(
    capture { use_ok 'MyWarner' },
    qr/^Deprected! run for your lives! at \Q$file\E line $line/,
    "Got the warning"
);

ok(!capture { no warnings 'deprecated'; use_ok 'MyWarner' }, "No warning");

done_testing;
