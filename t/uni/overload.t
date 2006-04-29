#!perl -w

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More tests => 68;

package UTF8Toggle;
use strict;

use overload '""' => 'stringify';

sub new {
    my $class = shift;
    my $value = shift;
    my $state = shift||0;
    return bless [$value, $state], $class;
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

my $u = UTF8Toggle->new("\311");
my $lc = lc $u;
is (length $lc, 1);
is ($lc, "\311", "E accute -> e accute");
$lc = lc $u;
is (length $lc, 1);
is ($lc, "\351", "E accute -> e accute");
$lc = lc $u;
is (length $lc, 1);
is ($lc, "\311", "E accute -> e accute");

$u = UTF8Toggle->new("\351");
my $uc = uc $u;
is (length $uc, 1);
is ($uc, "\351", "e accute -> E accute");
$uc = uc $u;
is (length $uc, 1);
is ($uc, "\311", "e accute -> E accute");
$uc = uc $u;
is (length $uc, 1);
is ($uc, "\351", "e accute -> E accute");

$u = UTF8Toggle->new("\311");
$lc = lcfirst $u;
is (length $lc, 1);
is ($lc, "\311", "E accute -> e accute");
$lc = lcfirst $u;
is (length $lc, 1);
is ($lc, "\351", "E accute -> e accute");
$lc = lcfirst $u;
is (length $lc, 1);
is ($lc, "\311", "E accute -> e accute");

$u = UTF8Toggle->new("\351");
$uc = ucfirst $u;
is (length $uc, 1);
is ($uc, "\351", "e accute -> E accute");
$uc = ucfirst $u;
is (length $uc, 1);
is ($uc, "\311", "e accute -> E accute");
$uc = ucfirst $u;
is (length $uc, 1);
is ($uc, "\351", "e accute -> E accute");

my $have_setlocale = 0;
eval {
    require POSIX;
    import POSIX ':locale_h';
    $have_setlocale++;
};

SKIP: {
    if (!$have_setlocale) {
	skip "No setlocale", 24;
    } elsif (!setlocale(&POSIX::LC_ALL, "en_GB.ISO8859-1")) {
	skip "Could not setlocale to en_GB.ISO8859-1", 24;
    } else {
	use locale;
	my $u = UTF8Toggle->new("\311");
	my $lc = lc $u;
	is (length $lc, 1);
	is ($lc, "\351", "E accute -> e accute");
	$lc = lc $u;
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
	$uc = uc $u;
	is (length $uc, 1);
	is ($uc, "\311", "e accute -> E accute");

	$u = UTF8Toggle->new("\311");
	$lc = lcfirst $u;
	is (length $lc, 1);
	is ($lc, "\351", "E accute -> e accute");
	$lc = lcfirst $u;
	is (length $lc, 1);
	is ($lc, "\351", "E accute -> e accute");
	$lc = lcfirst $u;
	is (length $lc, 1);
	is ($lc, "\351", "E accute -> e accute");

	$u = UTF8Toggle->new("\351");
	$uc = ucfirst $u;
	is (length $uc, 1);
	is ($uc, "\311", "e accute -> E accute");
	$uc = ucfirst $u;
	is (length $uc, 1);
	is ($uc, "\311", "e accute -> E accute");
	$uc = ucfirst $u;
	is (length $uc, 1);
	is ($uc, "\311", "e accute -> E accute");
    }
}

my $tmpfile = 'overload.tmp';

foreach my $operator (qw (print)) {
    foreach my $layer ('', ':utf8') {
	open my $fh, "+>$layer", $tmpfile or die $!;
	my $u = UTF8Toggle->new("\311\n");
	print $fh $u;
	print $fh $u;
	print $fh $u;
	my $l = UTF8Toggle->new("\351\n", 1);
	print $fh $l;
	print $fh $l;
	print $fh $l;

	seek $fh, 0, 0 or die $!;
	my $line;
	chomp ($line = <$fh>);
	is ($line, "\311", "$operator $layer");
	chomp ($line = <$fh>);
	is ($line, "\311", "$operator $layer");
	chomp ($line = <$fh>);
	is ($line, "\311", "$operator $layer");
	chomp ($line = <$fh>);
	is ($line, "\351", "$operator $layer");
	chomp ($line = <$fh>);
	is ($line, "\351", "$operator $layer");
	chomp ($line = <$fh>);
	is ($line, "\351", "$operator $layer");

	close $fh or die $!;
	unlink $tmpfile or die $!;
    }
}


END {
    1 while -f $tmpfile and unlink $tmpfile || die "unlink '$tmpfile': $!";
}
