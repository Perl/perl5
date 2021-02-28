package sysbinmode;

use strict;
use warnings;

our $hint_bits = 0x00800000;

our $VERSION = '0.01';

use constant _HINT_KEY => __PACKAGE__ . '/setting';

my %known_levels = (
    ':raw' => 1,
    ':utf8' => 2,
);

sub import {
    my $requested_level;

    if (@_ == 1) {
        $requested_level = ':raw';
    }
    elsif (!defined $_[1]) {
        require Carp;
        Carp::croak( sprintf "Give an I/O level to %s!", __PACKAGE__ );
    }
    else {
        $requested_level = $_[1];

        if (!exists $known_levels{$requested_level}) {
            require Carp;
            Carp::croak( sprintf "Bad I/O level to %s: %s", __PACKAGE__, $requested_level );
        }
    }

    $^H{ _HINT_KEY() } = $known_levels{$requested_level};

    return;
}

sub unimport {
    delete $^H{ _HINT_KEY() };
}

1;
