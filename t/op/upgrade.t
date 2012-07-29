#!./perl -w

# Check that we can "upgrade" from anything to anything else.
# Curiously, before this, lib/Math/Trig.t was the only code anywhere in the
# build or testsuite that upgraded an NV to an RV

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

my $can_peek;
if (!is_miniperl()) {
    require Config;
    $can_peek = $Config::Config{extensions} =~ /\bDevel\/Peek\b/;
    if ($can_peek) {
        require Devel::Peek;
        Devel::Peek->import('Dump');
    }
}

my $null;

$! = 1;
my %types = (
    null => $null,
    iv => 3,
    nv => .5,
    rv => [],
    pv => "Perl rules",
    pviv => 3,
    pvnv => 1==1,
    pvmg => "hello",
);
pos($types{pvmg}) = 1; # pos() is stored as magic

# This is somewhat cheating but I can't think of anything built in that I can
# copy that already has type PVIV
$types{pviv} = "Perl rules!";

my @keys = keys %types;
plan tests => @keys * @keys + ($can_peek ? @keys + 14 : 0);

if ($can_peek) {
    foreach my $type (@keys) {
        my $peek = peek($types{$type});
        ok(peek_is_type($peek, $type), "$type test value has right type", $peek);
    }
}

foreach my $source_type (@keys) {
    foreach my $dest_type (@keys) {
	# Pads re-using variables might contaminate this
	my $vars = {};
	$vars->{dest} = $types{$dest_type};
	$vars->{source} = $types{$source_type};
	# The assignment can potentially trigger assertion failures, so it's
	# useful to have the diagnostics about what was attempted printed first
	print "# Assigning $source_type to $dest_type\n";
	$vars->{dest} = $vars->{source};
	is ($vars->{dest}, $vars->{source});
    }
}

if ($can_peek) {
    # test minimal upgrades: according to the source value, not the
    # source type
    my @minimal = qw( null iv nv pv pvnv );
    my %dest;
    for my $type (@minimal) {
        my $mg = "hi";
        pos($mg) = 1;           # start as PVMG
        $mg = $types{$type};    # does not downgrade
        my $peek = peek($mg);
        ok(peek_is_type($peek, 'pvmg'), "\U$type\E assign does not downgrade PVMG", $peek);
        $dest{$type} = $mg;     # should only upgrade as needed
        $peek = peek($dest{$type});
        ok(peek_is_type($peek, $type), "\U$type\E minimal upgrade", $peek);
    }

    # test specific case of strings used as numbers
    {
        my $pviv = "1";
        my $foo = 1 << $pviv;
        my $peek = peek($pviv);
        ok(peek_is_type($peek, 'pviv'), "string used as integer should be PVIV", $peek);
        my $copy = $pviv;
        $peek = peek($copy);
        ok(peek_is_type($peek, 'pviv'), "string used as integer should copy to PVIV", $peek);
    }
    {
        my $pvnv = "1.1";
        my $foo = 2.2 * $pvnv;
        my $peek = peek($pvnv);
        ok(peek_is_type($peek, 'pvnv'), "string used as number should be PVNV", $peek);
        my $copy = $pvnv;
        $peek = peek($copy);
        ok(peek_is_type($peek, 'pvnv'), "string used as number should copy to PVNV", $peek);
    }
}


sub peek {
    open SAVERR, '>&STDERR';
    open STDERR, '>', "upgrade$$.tmp";
    Dump($_[0]);
    open STDERR, '>&SAVERR';
    close SAVERR;
    open my $fh, '<', "upgrade$$.tmp";
    local $/;
    <$fh>
}
sub peek_is_type {
    my ($peek, $expect) = @_;
    $expect =~ s/^rv/iv/;  # SVt_IV holds references these days
    $peek =~ /^SV = \U$expect\E\b/;
}
sub peek_flags {
    $_[0] =~ m{^ \s* FLAGS \s* = \s* \( (.+) \) }xm
      ? $1 : undef
}
