package Unicode::UCD;

use strict;
use warnings;

our $VERSION = '3.1.0';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(charinfo charblock charscript);

use Carp;

=head1 NAME

Unicode::UCD - Unicode character database

=head1 SYNOPSIS

    use Unicode::UCD 3.1.0;
    # requires that level of the Unicode character database

    use Unicode::UCD 'charinfo';
    my %charinfo   = charinfo($codepoint);

    use Unicode::UCD 'charblock';
    my $charblock  = charblock($codepoint);

    use Unicode::UCD 'charscript';
    my $charscript = charblock($codepoint);

=head1 DESCRIPTION

The Unicode module offers a simple interface to the Unicode Character
Database.

=cut

my $UNICODE;
my $BLOCKS;
my $SCRIPTS;

sub openunicode {
    my ($rfh, @path) = @_;
    my $f;
    unless (defined $$rfh) {
	for my $d (@INC) {
	    use File::Spec;
	    $f = File::Spec->catfile($d, "unicode", @path);
	    last if open($$rfh, $f);
	    undef $f;
	}
	croak __PACKAGE__, ": failed to find ",
              File::Spec->catfile(@path), " in @INC"
	    unless defined $f;
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
    script           script the character belongs to 

If no match is found, an empty hash is returned.

The C<block> property is the same as as returned by charinfo().  It is
not defined in the Unicode Character Database proper (Chapter 4 of the
Unicode 3.0 Standard) but instead in an auxiliary database (Chapter 14
of TUS3).  Similarly for the C<script> property.

Note that you cannot do (de)composition and casing based solely on the
above C<decomposition> and C<lower>, C<upper>, C<title>, properties,
you will need also the I<Composition Exclusions>, I<Case Folding>, and
I<SpecialCasing> tables, available as files F<CompExcl.txt>,
F<CaseFold.txt>, and F<SpecCase.txt> in the Perl distribution.

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
		$prop{block}  = charblock($code);
		$prop{script} = charscript($code);
		return %prop;
	    }
	}
    }
    return;
}

sub _search { # Binary search in a [[lo,hi,prop],[...],...] table.
    my ($table, $lo, $hi, $code) = @_;

    return if $lo > $hi;

    my $mid = int(($lo+$hi) / 2);

    if ($table->[$mid]->[0] < $code) {
	if (defined $table->[$mid]->[1] && $table->[$mid]->[1] >= $code) {
	    return $table->[$mid]->[2];
	} else {
	    _search($table, $mid + 1, $hi, $code);
	}
    } elsif ($table->[$mid]->[0] > $code) {
	_search($table, $lo, $mid - 1, $code);
    } else {
	return $table->[$mid]->[2];
    }
}

=head2 charblock

    use Unicode::UCD 'charblock';

    my $charblock = charblock(0x41);

charblock() returns the block the character belongs to, e.g.
C<Basic Latin>.  Note that not all the character positions within all
blocks are defined.

The name is the same name that is used in the C<\p{In...}> construct,
for example C<\p{InBasicLatin}> (spaces and dashes ('-') are squished
away from the names for the C<\p{In...}>, for example C<LatinExtendedA>
instead of C<Latin Extended-A>.

=cut

my @BLOCKS;

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

    _search(\@BLOCKS, 0, $#BLOCKS, $code);
}

=head2 charscript

    use Unicode::UCD 'charscript';

    my $charscript = charscript(0x41);

charscript() returns the script the character belongs to, e.g.
C<Latin>, C<Greek>, C<Han>.  Note that not all the character positions
within all scripts are defined.  

The difference between a character block and a script is that script
names are closer to the linguistic notion of a set of characters,
while block is more of an artifact of the Unicode character numbering.
For example the Latin B<script> is spread over several B<blocks>.

Note also that the script names are all in uppercase, e.g. C<HEBREW>,
while the block names are Capitalized and with intermixed spaces,
e.g. C<Yi Syllables>.

Unfortunately, currently (Perl 5.8.0) there is no regular expression
notation for matching scripts as there is for blocks (C<\p{In...}>.

=cut

my @SCRIPTS;

sub charscript {
    my $code = shift;

    unless (@SCRIPTS) {
	if (openunicode(\$SCRIPTS, "Scripts.txt")) {
	    while (<$SCRIPTS>) {
		if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s+;\s+(\w+)/) {
		    push @SCRIPTS, [ hex($1), $2 ? hex($2) : undef, $3 ];
		}
	    }
	    close($SCRIPTS);
	    @SCRIPTS = sort { $a->[0] <=> $b->[0] } @SCRIPTS;
	}
    }

    _search(\@SCRIPTS, 0, $#SCRIPTS, $code);
}

=head1 IMPLEMENTATION NOTE

The first use of L<charinfo> opens a read-only filehandle to the Unicode
Character Database.  The filehandle is kept open for further queries.

=head1 AUTHOR

Jarkko Hietaniemi

=cut

1;
