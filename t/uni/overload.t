#!perl -w

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More tests => 16;

package UTF8Toggle;
use strict;

use overload '""' => 'stringify';

sub new {
    my $class = shift;
    return bless [shift, 0], $class;
}

sub stringify {
    my $self = shift;
    $self->[1] = ! $self->[1];
    if ($self->[1]) {
	utf8::downgrade($self->[0]);
    } else {
	utf8::upgrade($self->[0]);
    }
    $self->[0];
}

package main;

# Bug 34297
foreach my $t ("ASCII", "B\366se") {
    my $length = length $t;

    my $u = UTF8Toggle->new($t);
    is (length $u, $length, "length of '$t'");
    is (length $u, $length, "length of '$t'");
    is (length $u, $length, "length of '$t'");
    is (length $u, $length, "length of '$t'");
}

my $have_setlocale = 0;
eval {
    require POSIX;
    import POSIX ':locale_h';
    $have_setlocale++;
};

SKIP: {
    if (!$have_setlocale) {
	skip "No setlocale", 4;
    } elsif (!setlocale(&POSIX::LC_ALL, "en_GB.ISO8859-1")) {
	skip "Could not setlocale to en_GB.ISO8859-1", 4;
    } else {
	use locale;
	my $u = UTF8Toggle->new("\311");
	my $lc = lc $u;
	is (length $lc, 1);
	is ($lc, "\351", "E accute -> e accute");
	$lc = lc $u;
	is (length $lc, 1);
	is ($lc, "\351", "E accute -> e accute");

	$u = UTF8Toggle->new("\351");
	my $uc = uc $u;
	is (length $uc, 1);
	is ($uc, "\311", "e accute -> E accute");
	$uc = uc $u;
	is (length $uc, 1);
	is ($uc, "\311", "e accute -> E accute");
    }
}
