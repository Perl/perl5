package UnicodeCD;

use strict;
use warnings;

our $VERSION = '0.1';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(charinfo
		    charblock charscript
		    charblocks charscripts
		    charinrange
		    compexcl
		    casefold casespec);

use Carp;

=head1 NAME

UnicodeCD - Unicode character database

=head1 SYNOPSIS

    use UnicodeCD 'charinfo';
    my $charinfo   = charinfo($codepoint);

    use UnicodeCD 'charblock';
    my $charblock  = charblock($codepoint);

    use UnicodeCD 'charscript';
    my $charscript = charblock($codepoint);

    use UnicodeCD 'charblocks';
    my $charblocks = charblocks();

    use UnicodeCD 'charscripts';
    my %charscripts = charscripts();

    use UnicodeCD qw(charscript charinrange);
    my $range = charscript($script);
    print "looks like $script\n" if charinrange($range, $codepoint);

    use UnicodeCD 'compexcl';
    my $compexcl = compexcl($codepoint);

    my $unicode_version = UnicodeCD::UnicodeVersion();

=head1 DESCRIPTION

The UnicodeCD module offers a simple interface to the Unicode Character
Database.

=cut

my $UNICODEFH;
my $BLOCKSFH;
my $SCRIPTSFH;
my $VERSIONFH;
my $COMPEXCLFH;
my $CASEFOLDFH;
my $CASESPECFH;

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

    use UnicodeCD 'charinfo';

    my $charinfo = charinfo(0x41);

charinfo() returns a reference to a hash that has the following fields
as defined by the Unicode standard:

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

If no match is found, a reference to an empty hash is returned.

The C<block> property is the same as as returned by charinfo().  It is
not defined in the Unicode Character Database proper (Chapter 4 of the
Unicode 3.0 Standard) but instead in an auxiliary database (Chapter 14
of TUS3).  Similarly for the C<script> property.

Note that you cannot do (de)composition and casing based solely on the
above C<decomposition> and C<lower>, C<upper>, C<title>, properties,
you will need also the compexcl(), casefold(), and casespec() functions.

=cut

sub _getcode {
    my $arg = shift;

    if ($arg =~ /^\d+$/) {
	return $arg;
    } elsif ($arg =~ /^(?:U\+|0x)?([[:xdigit:]]+)$/) {
	return hex($1);
    }

    return;
}

sub charinfo {
    my $arg  = shift;
    my $code = _getcode($arg);
    croak __PACKAGE__, "::charinfo: unknown code '$arg'"
	unless defined $code;
    my $hexk = sprintf("%04X", $code);

    openunicode(\$UNICODEFH, "Unicode.txt");
    if (defined $UNICODEFH) {
	use Search::Dict;
	if (look($UNICODEFH, "$hexk;") >= 0) {
	    my $line = <$UNICODEFH>;
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
		return \%prop;
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
	if ($table->[$mid]->[1] >= $code) {
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

sub charinrange {
    my ($range, $arg) = @_;
    my $code = _getcode($arg);
    croak __PACKAGE__, "::charinrange: unknown code '$arg'"
	unless defined $code;
    _search($range, 0, $#$range, $code);
}

=head2 charblock

    use UnicodeCD 'charblock';

    my $charblock = charblock(0x41);
    my $charblock = charblock(1234);
    my $charblock = charblock("0x263a");
    my $charblock = charblock("U+263a");

    my $ranges    = charblock('Armenian');

With a B<code point argument> charblock() returns the block the character
belongs to, e.g.  C<Basic Latin>.  Note that not all the character
positions within all blocks are defined.

If supplied with an argument that can't be a code point, charblock()
tries to do the opposite and interpret the argument as a character
block.  The return value is a I<range>: an anonymous list that
contains anonymous lists, which in turn contain I<start-of-range>,
I<end-of-range> code point pairs.  You can test whether a code point
is in a range using the L</charinrange> function.  If the argument is
not a known charater block, C<undef> is returned.

=cut

my @BLOCKS;
my %BLOCKS;

sub _charblocks {
    unless (@BLOCKS) {
	if (openunicode(\$BLOCKSFH, "Blocks.txt")) {
	    while (<$BLOCKSFH>) {
		if (/^([0-9A-F]+)\.\.([0-9A-F]+);\s+(.+)/) {
		    my ($lo, $hi) = (hex($1), hex($2));
		    my $subrange = [ $lo, $hi, $3 ];
		    push @BLOCKS, $subrange;
		    push @{$BLOCKS{$3}}, $subrange;
		}
	    }
	    close($BLOCKSFH);
	}
    }
}

sub charblock {
    my $arg = shift;

    _charblocks() unless @BLOCKS;

    my $code = _getcode($arg);

    if (defined $code) {
	_search(\@BLOCKS, 0, $#BLOCKS, $code);
    } else {
	if (exists $BLOCKS{$arg}) {
	    return $BLOCKS{$arg};
	} else {
	    return;
	}
    }
}

=head2 charscript

    use UnicodeCD 'charscript';

    my $charscript = charscript(0x41);
    my $charscript = charscript(1234);
    my $charscript = charscript("U+263a");

    my $ranges     = charscript('Thai');

With a B<code point argument> charscript() returns the script the
character belongs to, e.g.  C<Latin>, C<Greek>, C<Han>.

If supplied with an argument that can't be a code point, charscript()
tries to do the opposite and interpret the argument as a character
script.  The return value is a I<range>: an anonymous list that
contains anonymous lists, which in turn contain I<start-of-range>,
I<end-of-range> code point pairs.  You can test whether a code point
is in a range using the L</charinrange> function.  If the argument is
not a known charater script, C<undef> is returned.

=cut

my @SCRIPTS;
my %SCRIPTS;

sub _charscripts {
    unless (@SCRIPTS) {
	if (openunicode(\$SCRIPTSFH, "Scripts.txt")) {
	    while (<$SCRIPTSFH>) {
		if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s+;\s+(\w+)/) {
		    my ($lo, $hi) = (hex($1), $2 ? hex($2) : hex($1));
		    my $script = lc($3);
		    $script =~ s/\b(\w)/uc($1)/ge;
		    my $subrange = [ $lo, $hi, $script ];
		    push @SCRIPTS, $subrange;
		    push @{$SCRIPTS{$script}}, $subrange;
		}
	    }
	    close($SCRIPTSFH);
	    @SCRIPTS = sort { $a->[0] <=> $b->[0] } @SCRIPTS;
	}
    }
}

sub charscript {
    my $arg = shift;

    _charscripts() unless @SCRIPTS;

    my $code = _getcode($arg);

    if (defined $code) {
	_search(\@SCRIPTS, 0, $#SCRIPTS, $code);
    } else {
	if (exists $SCRIPTS{$arg}) {
	    return $SCRIPTS{$arg};
	} else {
	    return;
	}
    }
}

=head2 charblocks

    use UnicodeCD 'charblocks';

    my $charblocks = charblocks();

charblocks() returns a reference to a hash with the known block names
as the keys, and the code point ranges (see L</charblock>) as the values.

=cut

sub charblocks {
    _charblocks() unless %BLOCKS;
    return \%BLOCKS;
}

=head2 charscripts

    use UnicodeCD 'charscripts';

    my %charscripts = charscripts();

charscripts() returns a hash with the known script names as the keys,
and the code point ranges (see L</charscript>) as the values.

=cut

sub charscripts {
    _charscripts() unless %SCRIPTS;
    return \%SCRIPTS;
}

=head2 Blocks versus Scripts

The difference between a block and a script is that scripts are closer
to the linguistic notion of a set of characters required to present
languages, while block is more of an artifact of the Unicode character
numbering and separation into blocks of 256 characters.

For example the Latin B<script> is spread over several B<blocks>, such
as C<Basic Latin>, C<Latin 1 Supplement>, C<Latin Extended-A>, and
C<Latin Extended-B>.  On the other hand, the Latin script does not
contain all the characters of the C<Basic Latin> block (also known as
the ASCII): it includes only the letters, not for example the digits
or the punctuation.

For blocks see http://www.unicode.org/Public/UNIDATA/Blocks.txt

For scripts see UTR #24: http://www.unicode.org/unicode/reports/tr24/

=head2 Matching Scripts and Blocks

Both scripts and blocks can be matched using the regular expression
construct C<\p{In...}> and its negation C<\P{In...}>.

The name of the script or the block comes after the C<In>, for example
C<\p{InCyrillic}>, C<\P{InBasicLatin}>.  Spaces and dashes ('-') are
removed from the names for the C<\p{In...}>, for example
C<LatinExtendedA> instead of C<Latin Extended-A>.

There are a few cases where there exists both a script and a block by
the same name, in these cases the block version has C<Block> appended:
C<\p{InKatakana}> is the script, C<\p{InKatakanaBlock}> is the block.

=head2 Code Point Arguments

A <code point argument> is either a decimal or a hexadecimal scalar,
or "U+" followed by hexadecimals.

=head2 charinrange

In addition to using the C<\p{In...}> and C<\P{In...}> constructs, you
can also test whether a code point is in the I<range> as returned by
L</charblock> and L</charscript> or as the values of the hash returned
by L</charblocks> and </charscripts> by using charinrange():

    use UnicodeCD qw(charscript charinrange);

    $range = charscript('Hiragana');
    print "looks like hiragana\n" if charinrange($range, $codepoint);

=cut

=head2 compexcl

    use UnicodeCD 'compexcl';

    my $compexcl = compexcl("09dc");

The compexcl() returns the composition exclusion (that is, if the
character should not be produced during a precomposition) of the 
character specified by a B<code point argument>.

If there is a composition exclusion for the character, true is
returned.  Otherwise, false is returned.

=cut

my %COMPEXCL;

sub _compexcl {
    unless (%COMPEXCL) {
	if (openunicode(\$COMPEXCLFH, "CompExcl.txt")) {
	    while (<$COMPEXCLFH>) {
		if (/^([0-9A-F]+) \# /) {
		    my $code = hex($1);
		    $COMPEXCL{$code} = undef;
		}
	    }
	    close($COMPEXCLFH);
	}
    }
}

sub compexcl {
    my $arg  = shift;
    my $code = _getcode($arg);

    _compexcl() unless %COMPEXCL;

    return exists $COMPEXCL{$code};
}

=head2 casefold

    use UnicodeCD 'casefold';

    my %casefold = casefold("09dc");

The casefold() returns the locale-independent case folding of the
character specified by a B<code point argument>.

If there is a case folding for that character, a reference to a hash
with the following fields is returned:

    key

    code             code point with at least four hexdigits
    status           "C", "F", "S", or "I"
    mapping          one or more codes separated by spaces

The meaning of the I<status> is as follows:

   C                 common case folding, common mappings shared
                     by both simple and full mappings
   F                 full case folding, mappings that cause strings
                     to grow in length. Multiple characters are separated
                     by spaces
   S                 simple case folding, mappings to single characters
                     where different from F
   I                 special case for dotted uppercase I and
                     dotless lowercase i
                     - If this mapping is included, the result is
                       case-insensitive, but dotless and dotted I's
                       are not distinguished
                     - If this mapping is excluded, the result is not
                       fully case-insensitive, but dotless and dotted
                       I's are distinguished

If there is no case folding for that character, C<undef> is returned.

For more information about case mappings see
http://www.unicode.org/unicode/reports/tr21/

=cut

my %CASEFOLD;

sub _casefold {
    unless (%CASEFOLD) {
	if (openunicode(\$CASEFOLDFH, "CaseFold.txt")) {
	    while (<$CASEFOLDFH>) {
		if (/^([0-9A-F]+); ([CFSI]); ([0-9A-F]+(?: [0-9A-F]+)*);/) {
		    my $code = hex($1);
		    $CASEFOLD{$code} = { code    => $1,
					 status  => $2,
					 mapping => $3 };
		}
	    }
	    close($CASEFOLDFH);
	}
    }
}

sub casefold {
    my $arg  = shift;
    my $code = _getcode($arg);

    _casefold() unless %CASEFOLD;

    return $CASEFOLD{$code};
}

=head2 casespec

    use UnicodeCD 'casespec';

    my %casespec = casespec("09dc");

The casespec() returns the potentially locale-dependent case mapping
of the character specified by a B<code point argument>.  The mapping
may change the length of the string (which the basic Unicode case
mappings as returned by charinfo() never do).

If there is a case folding for that character, a reference to a hash
with the following fields is returned:

    key

    code             code point with at least four hexdigits
    lower            lowercase
    title            titlecase
    upper            uppercase
    condition        condition list (may be undef)

The C<condition> is optional.  Where present, it consists of one or
more I<locales> or I<contexts>, separated by spaces (other than as
used to separate elements, spaces are to be ignored).  A condition
list overrides the normal behavior if all of the listed conditions are
true.  Case distinctions in the condition list are not significant.
Conditions preceded by "NON_" represent the negation of the condition

A I<locale> is defined as a 2-letter ISO 3166 country code, possibly
followed by a "_" and a 2-letter ISO language code (, possibly followed
by a "_" and a variant code).  You can find the list of those codes
in L<Locale::Country> and L<Locale::Language>.

A I<context> is one of the following choices:

    FINAL            The letter is not followed by a letter of
                     general category L (e.g. Ll, Lt, Lu, Lm, or Lo)
    MODERN           The mapping is only used for modern text
    AFTER_i          The last base character was "i" 0069

For more information about case mappings see
http://www.unicode.org/unicode/reports/tr21/

=cut

my %CASESPEC;

sub _casespec {
    unless (%CASESPEC) {
	if (openunicode(\$CASESPECFH, "SpecCase.txt")) {
	    while (<$CASESPECFH>) {
		if (/^([0-9A-F]+); ([0-9A-F]+(?: [0-9A-F]+)*)?; ([0-9A-F]+(?: [0-9A-F]+)*)?; ([0-9A-F]+(?: [0-9A-F]+)*)?; (\w+(?: \w+)*)?/) {
		    my $code = hex($1);
		    $CASESPEC{$code} = { code      => $1,
					 lower     => $2,
					 title     => $3,
					 upper     => $4,
					 condition => $5 };
		}
	    }
	    close($CASESPECFH);
	}
    }
}

sub casespec {
    my $arg  = shift;
    my $code = _getcode($arg);

    _casespec() unless %CASESPEC;

    return $CASESPEC{$code};
}

=head2 UnicodeCD::UnicodeVersion

UnicodeCD::UnicodeVersion() returns the version of the Unicode Character
Database, in other words, the version of the Unicode standard the
database implements.

=cut

my $UNICODEVERSION;

sub UnicodeVersion {
    unless (defined $UNICODEVERSION) {
	openunicode(\$VERSIONFH, "version");
	chomp($UNICODEVERSION = <$VERSIONFH>);
	close($VERSIONFH);
	croak __PACKAGE__, "::VERSION: strange version '$UNICODEVERSION'"
	    unless $UNICODEVERSION =~ /^\d+(?:\.\d+)+$/;
    }
    return $UNICODEVERSION;
}

=head2 Implementation Note

The first use of charinfo() opens a read-only filehandle to the Unicode
Character Database (the database is included in the Perl distribution).
The filehandle is then kept open for further queries.

=head1 AUTHOR

Jarkko Hietaniemi

=cut

1;
