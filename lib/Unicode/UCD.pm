package Unicode::UCD;

use strict;
use warnings;

our $VERSION = '3.1.0';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(charinfo charblock);

use Carp;

=head1 NAME

Unicode - Unicode character database

=head1 SYNOPSIS

    use Unicode::UCD 3.1.0;
    # requires that level of the Unicode character database

    use Unicode::UCD 'charinfo';
    my %charinfo  = charinfo($codepoint);

    use Unicode::UCD 'charblock';
    my $charblock = charblock($codepoint);

=head1 DESCRIPTION

The Unicode module offers a simple interface to the Unicode Character
Database.

=cut

my $UNICODE;
my $BLOCKS;

sub openunicode {
    my ($rfh, @path) = @_;
    my $f;
    unless (defined $$rfh) {
	for my $d (@INC) {
	    use File::Spec;
	    $f = File::Spec->catfile($d, "unicode", @path);
	    if (open($$rfh, $f)) {
		last;
	    } else {
		croak __PACKAGE__, ": open '$f' failed: $!\n";
	    }
	}
	croak __PACKAGE__, ": failed to find ",join("/",@path)," in @INC\n"
	    unless defined $rfh;
    }
    return $f;
}

=head2 charinfo

    use Unicode::UCD 'charinfo';

    my %charinfo = charinfo(0x41);

charinfo() returns a hash that has the following fields as defined
by the Unicode standard:

    key

    code             code point with at least four hexdigits
    name             name of the character IN UPPER CASE
    category         general category of the character
    combining        classes used in the Canonical Ordering Algorithm
    bidi             bidirectional category
    decomposition    character decomposition mapping
    decimal          if decimal digit this is the integer numeric value
    digit            if digit this is the numeric value
    numeric          if numeric is the integer or rational numeric value
    mirrored         if mirrored in bidirectional text
    unicode10        Unicode 1.0 name if existed and different
    comment          ISO 10646 comment field
    upper            uppercase equivalent mapping
    lower            lowercase equivalent mapping
    title            titlecase equivalent mapping
    block            block the character belongs to (used in \p{In...})

If no match is found, an empty hash is returned.

The C<block> property is the same as as returned by charinfo().
(It is not defined in the Unicode Character Database proper but
instead in an auxiliary database.)

=cut

sub charinfo {
    my $code = shift;
    my $hexk = sprintf("%04X", $code);

    openunicode(\$UNICODE, "Unicode.txt");
    if (defined $UNICODE) {
	use Search::Dict;
	if (look($UNICODE, "$hexk;") >= 0) {
	    my $line = <$UNICODE>;
	    chomp $line;
	    my %prop;
	    @prop{qw(
		     code name category
		     combining bidi decomposition
		     decimal digit numeric
		     mirrored unicode10 comment
		     upper lower title
		    )} = split(/;/, $line, -1);
	    if ($prop{code} eq $hexk) {
		$prop{block} = charblock($code);
		return %prop;
	    }
	}
    }
    return;
}

=head2 charblock

    use Unicode::UCD 'charblock';

    my $charblock = charblock(0x41);

charblock() returns the block the character belongs to, e.g.
C<Basic Latin>.  Note that not all the character positions within all
block are defined.

The name is the same name that is used in the C<\p{In...}> construct,
for example C<\p{InBasicLatin}> (spaces and dashes ('-') are squished
away from the names for the C<\p{In...}>.

=cut

my @BLOCKS;

sub _charblock {
    my ($code, $lo, $hi) = @_;

    return if $lo > $hi;

    my $mid = int(($lo+$hi) / 2);

    if ($BLOCKS[$mid]->[0] < $code) {
	if ($BLOCKS[$mid]->[1] >= $code) {
	    return $BLOCKS[$mid]->[2];
	} else {
	    _charblock($code, $mid + 1, $hi);
	}
    } elsif ($BLOCKS[$mid]->[0] > $code) {
	_charblock($code, $lo, $mid - 1);
    } else {
	return $BLOCKS[$mid]->[2];
    }
}

sub charblock {
    my $code = shift;

    unless (@BLOCKS) {
	if (openunicode(\$BLOCKS, "Blocks.pl")) {
	    while (<$BLOCKS>) {
		if (/^([0-9A-F]+)\s+([0-9A-F]+)\s+(.+)/) {
		    push @BLOCKS, [ hex($1), hex($2), $3 ];
		}
	    }
	    close($BLOCKS);
	}
    }

    _charblock($code, 0, $#BLOCKS);
}

=head1 AUTHOR

Jarkko Hietaniemi

=cut

1;
