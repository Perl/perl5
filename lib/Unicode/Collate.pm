package Unicode::Collate;

BEGIN {
    if (ord("A") == 193) {
	die "Unicode::Collate not ported to EBCDIC\n";
    }
}

use 5.006;
use strict;
use warnings;
use Carp;
use File::Spec;

require Exporter;

our $VERSION = '0.21';
our $PACKAGE = __PACKAGE__;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ();
our @EXPORT_OK = ();
our @EXPORT = ();

(our $Path = $INC{'Unicode/Collate.pm'}) =~ s/\.pm$//;
our $KeyFile = "allkeys.txt";

our $UNICODE_VERSION;

eval { require Unicode::UCD };

unless ($@) {
    $UNICODE_VERSION = Unicode::UCD::UnicodeVersion();
}
else { # XXX, Perl 5.6.1
    my($f, $fh);
    foreach my $d (@INC) {
	$f = File::Spec->catfile($d, "unicode", "Unicode.301");
	if (open($fh, $f)) {
	    $UNICODE_VERSION = '3.0.1';
	    close $fh;
	    last;
	}
    }
}

our $getCombinClass; # coderef for combining class from Unicode::Normalize

use constant Min2   => 0x20;    # minimum weight at level 2
use constant Min3   => 0x02;    # minimum weight at level 3

# format for pack
use constant VCE_FORMAT => 'Cn4'; # for variable + CE with 4 levels

# values of variable
use constant NON_VAR => 0; # Non-Variable character
use constant VAR     => 1; # Variable character

our $DefaultRearrange = [ 0x0E40..0x0E44, 0x0EC0..0x0EC4 ];

sub UCA_Version { "9" }

sub Base_Unicode_Version { $UNICODE_VERSION || 'unknown' }

my (%AlternateOK);
@AlternateOK{ qw/
    blanked  non-ignorable  shifted  shift-trimmed
  / } = ();

our @ChangeOK = qw/
    alternate backwards level normalization rearrange
    katakana_before_hiragana upper_before_lower
    overrideHangul overrideCJK preprocess UCA_Version
  /;

our @ChangeNG = qw/
    entry entries table combining maxlength
    ignoreChar ignoreName undefChar undefName
    versionTable alternateTable backwardsTable forwardsTable rearrangeTable
    derivCode normCode rearrangeHash isShift L3ignorable
  /;
# The hash key 'ignored' is deleted at VERSION 0.21.

my (%ChangeOK, %ChangeNG);
@ChangeOK{ @ChangeOK } = ();
@ChangeNG{ @ChangeNG } = ();

sub change {
    my $self = shift;
    my %hash = @_;
    my %old;
    foreach my $k (keys %hash) {
	if (exists $ChangeOK{$k}) {
	    $old{$k} = $self->{$k};
	    $self->{$k} = $hash{$k};
	}
	elsif (exists $ChangeNG{$k}) {
	    croak "change of $k via change() is not allowed!";
	}
	# else => ignored
    }
    $self->checkCollator;
    return wantarray ? %old : $self;
}

sub checkCollator {
    my $self = shift;
    croak "Illegal level lower than 1 (passed $self->{level})."
	if $self->{level} < 1;
    croak "A level higher than 4 (passed $self->{level}) is not supported."
	if 4 < $self->{level};

    $self->{derivCode} =
	$self->{UCA_Version} == -1 ? \&broken_derivCE :
	$self->{UCA_Version} ==  8 ? \&derivCE_8 :
	$self->{UCA_Version} ==  9 ? \&derivCE_9 :
      croak "Illegal UCA version (passed $self->{UCA_Version}).";

    $self->{alternate} = lc($self->{alternate});
    croak "$PACKAGE unknown alternate tag name: $self->{alternate}"
	unless exists $AlternateOK{ $self->{alternate} };

    $self->{isShift} = $self->{alternate} eq 'shifted' ||
		$self->{alternate} eq 'shift-trimmed';

    $self->{backwards} = []
	if ! defined $self->{backwards};
    $self->{backwards} = [ $self->{backwards} ]
	if ! ref $self->{backwards};

    $self->{rearrange} = []
	if ! defined $self->{rearrange};
    croak "$PACKAGE: A list for rearrangement must be store in an ARRAYREF"
	if ! ref $self->{rearrange};

    # keys of $self->{rearrangeHash} are $self->{rearrange}.
    $self->{rearrangeHash} = undef;

    if (@{ $self->{rearrange} }) {
	@{ $self->{rearrangeHash} }{ @{ $self->{rearrange} } } = ();
    }

    $self->{normCode} = undef;

    if (defined $self->{normalization}) {
	eval { require Unicode::Normalize };
	croak "Unicode/Normalize.pm is required to normalize strings: $@"
	    if $@;

	Unicode::Normalize->import();
	$getCombinClass = \&Unicode::Normalize::getCombinClass
	    if ! $getCombinClass;

	$self->{normCode} =
	    $self->{normalization} =~ /^(?:NF)?C$/  ? \&NFC :
	    $self->{normalization} =~ /^(?:NF)?D$/  ? \&NFD :
	    $self->{normalization} =~ /^(?:NF)?KC$/ ? \&NFKC :
	    $self->{normalization} =~ /^(?:NF)?KD$/ ? \&NFKD :
	  croak "$PACKAGE unknown normalization form name: "
		. $self->{normalization};
    }
    return;
}

sub new
{
    my $class = shift;
    my $self = bless { @_ }, $class;

    # If undef is passed explicitly, no file is read.
    $self->{table} = $KeyFile if ! exists $self->{table};
    $self->read_table if defined $self->{table};

    if ($self->{entry}) {
	$self->parseEntry($_) foreach split /\n/, $self->{entry};
    }

    $self->{level} ||= 4;
    $self->{UCA_Version} ||= UCA_Version();

    $self->{overrideHangul} = ''
	if ! exists $self->{overrideHangul};
    $self->{overrideCJK} = ''
	if ! exists $self->{overrideCJK};
    $self->{normalization} = 'D'
	if ! exists $self->{normalization};
    $self->{alternate} = $self->{alternateTable} || 'shifted'
	if ! exists $self->{alternate};
    $self->{rearrange} = $self->{rearrangeTable} || $DefaultRearrange
	if ! exists $self->{rearrange};
    $self->{backwards} = $self->{backwardsTable}
	if ! exists $self->{backwards};

    $self->checkCollator;

    return $self;
}

sub read_table {
    my $self = shift;
    my $file = $self->{table} ne '' ? $self->{table} : $KeyFile;

    my $filepath = File::Spec->catfile($Path, $file);
    open my $fk, "<$filepath"
	or croak "File does not exist at $filepath";

    while (<$fk>) {
	next if /^\s*#/;
	if (/^\s*\@/) {
	    if    (/^\s*\@version\s*(\S*)/) {
		$self->{versionTable} ||= $1;
	    }
	    elsif (/^\s*\@alternate\s+(\S*)/) {
		$self->{alternateTable} ||= $1;
	    }
	    elsif (/^\s*\@backwards\s+(\S*)/) {
		push @{ $self->{backwardsTable} }, $1;
	    }
	    elsif (/^\s*\@forwards\s+(\S*)/) { # parhaps no use
		push @{ $self->{forwardsTable} }, $1;
	    }
	    elsif (/^\s*\@rearrange\s+(.*)/) { # (\S*) is NG
		push @{ $self->{rearrangeTable} }, _getHexArray($1);
	    }
	    next;
	}
	$self->parseEntry($_);
    }
    close $fk;
}


##
## get $line, parse it, and write an entry in $self
##
sub parseEntry
{
    my $self = shift;
    my $line = shift;
    my($name, $ele, @key);

    return if $line !~ /^\s*[0-9A-Fa-f]/;

    # removes comment and gets name
    $name = $1
	if $line =~ s/[#%]\s*(.*)//;
    return if defined $self->{undefName} && $name =~ /$self->{undefName}/;

    # gets element
    my($e, $k) = split /;/, $line;
    croak "Wrong Entry: <charList> must be separated by ';' from <collElement>"
	if ! $k;

    my @e = _getHexArray($e);
    return if !@e;

    $ele = pack('U*', @e);
    return if defined $self->{undefChar} && $ele =~ /$self->{undefChar}/;

    my $combining = 1; # primary = 0, secondary != 0;
    my $level3ignore;

    # replace with completely ignorable
    if (defined $self->{ignoreName} && $name =~ /$self->{ignoreName}/ ||
	defined $self->{ignoreChar} && $ele  =~ /$self->{ignoreChar}/)
    {
	$k = '[.0000.0000.0000.0000]';
    }

    foreach my $arr ($k =~ /\[([^\[\]]+)\]/g) { # SPACEs allowed
	my $var = $arr =~ /\*/; # exactly /^\*/ but be lenient.
	my @arr = _getHexArray($arr);
	push @key, pack(VCE_FORMAT, $var, @arr);
	$combining = 0 unless $arr[0] == 0 && $arr[1] != 0;
	$level3ignore = 1 if $arr[0] == 0 && $arr[1] == 0 && $arr[2] == 0;
    }

    $self->{entries}{$ele} = \@key;

    $self->{combining}{$ele} = 1
	if $combining;

    $self->{L3ignorable}{$e[0]} = 1
	if @e == 1 && $level3ignore;

    $self->{maxlength}{ord $ele} = scalar @e if @e > 1;
}

##
## arrayref CE = altCE(bool variable?, list[num] weights)
##
sub altCE
{
    my $self = shift;
    my($var, @c) = unpack(VCE_FORMAT, shift);

    $self->{alternate} eq 'blanked' ?
	$var ? [0,0,0,$c[3]] : \@c :
    $self->{alternate} eq 'non-ignorable' ?
	\@c :
    $self->{alternate} eq 'shifted' ?
	$var ? [0,0,0,$c[0] ] : [ @c[0..2], $c[0]+$c[1]+$c[2] ? 0xFFFF : 0 ] :
    $self->{alternate} eq 'shift-trimmed' ?
	$var ? [0,0,0,$c[0] ] : [ @c[0..2], 0 ] :
        croak "$PACKAGE unknown alternate name: $self->{alternate}";
}

sub viewSortKey
{
    my $self = shift;
    my $ver = $self->{UCA_Version};

    my $key  = $self->getSortKey(@_);
    my $view = join " ", map sprintf("%04X", $_), unpack 'n*', $key;
    if ($ver <= 8) {
	$view =~ s/ ?0000 ?/|/g;
    } else {
	$view =~ s/\b0000\b/|/g;
    }
    return "[$view]";
}


##
## list[strings] elements = splitCE(string arg)
##
sub splitCE
{
    my $self = shift;
    my $code = $self->{preprocess};
    my $norm = $self->{normCode};
    my $ent  = $self->{entries};
    my $max  = $self->{maxlength};
    my $reH  = $self->{rearrangeHash};
    my $L3i  = $self->{L3ignorable};
    my $ver9 = $self->{UCA_Version} > 8;

    my $str = ref $code ? &$code(shift) : shift;
    $str = &$norm($str) if ref $norm;

    my @src = unpack('U*', $str);
    my @buf;

    # rearrangement
    if ($reH) {
	for (my $i = 0; $i < @src; $i++) {
	    if (exists $reH->{ $src[$i] } && $i + 1 < @src) {
		($src[$i], $src[$i+1]) = ($src[$i+1], $src[$i]);
		$i++;
	    }
	}
    }

    if ($ver9) {
	@src = grep ! $L3i->{$_}, @src;
    }

    for (my $i = 0; $i < @src; $i++) {
	my $ch;
	my $u = $src[$i];

	# non-characters
	next if ! defined $u
	    || ($u < 0 || 0x10FFFF < $u)      # out of range
	    || (($u & 0xFFFE) == 0xFFFE)      # ??FFFE or ??FFFF (cf. utf8.c)
	    || (0xD800 <= $u && $u <= 0xDFFF) # unpaired surrogates
	    || (0xFDD0 <= $u && $u <= 0xFDEF) # non-character
	;

	if ($max->{$u}) { # contract
	    for (my $j = $max->{$u}; $j >= 1; $j--) {
		next unless $i+$j-1 < @src;
		$ch = pack 'U*', @src[$i .. $i+$j-1];
		$i += $j-1, last if $ent->{$ch};
	    }
	} else {
	    $ch = pack('U', $u);
	}

	# with Combining Char (UTS#10, 4.2.1), here requires Unicode::Normalize.
	if ($getCombinClass && defined $ch) {
	    for (my $j = $i+1; $j < @src; $j++) {
		next unless defined $src[$j];
		last unless $getCombinClass->( $src[$j] );
		my $comb = pack 'U', $src[$j];
		next if ! $ent->{ $ch.$comb };
		$ch .= $comb;
		$src[$j] = undef;
	    }
	}
	push @buf, $ch;
    }
    wantarray ? @buf : \@buf;
}


##
## list[arrayrefs] weight = getWt(string element)
##
sub getWt
{
    my $self = shift;
    my $ch   = shift;
    my $ent  = $self->{entries};
    my $cjk  = $self->{overrideCJK};
    my $hang = $self->{overrideHangul};
    my $der  = $self->{derivCode};

    return if !defined $ch;
    return map($self->altCE($_), @{ $ent->{$ch} })
	if $ent->{$ch};

    my $u = unpack('U', $ch);

    if (0xAC00 <= $u && $u <= 0xD7A3) { # is_Hangul
	return map $self->altCE($_),
	    $hang
		? map(pack(VCE_FORMAT, NON_VAR, @$_), &$hang($u))
		: defined $hang
		    ? map({
			    my $v = $_;
			    my $vCE = $ent->{pack('U', $v)};
			    $vCE ? @$vCE : $der->($v);
			} _decompHangul($u))
		    : $der->($u);
    }
    elsif (0x3400 <= $u && $u <= 0x4DB5 ||
	   0x4E00 <= $u && $u <= 0x9FA5 ||
	   0x20000 <= $u && $u <= 0x2A6D6) { # CJK Ideograph
	return map $self->altCE($_),
	    $cjk
		? map(pack(VCE_FORMAT, NON_VAR, @$_), &$cjk($u))
		: defined $cjk && $self->{UCA_Version} <= 8 && $u < 0x10000
		    ? pack(VCE_FORMAT, NON_VAR, $u, 0x20, 0x02, $u)
		    : $der->($u);
    }
    else {
	return map $self->altCE($_), $der->($u);
    }
}

##
## int = index(string, substring)
##
sub index
{
    my $self = shift;
    my $lev  = $self->{level};
    my $comb = $self->{combining};
    my $str  = $self->splitCE(shift);
    my $sub  = $self->splitCE(shift);

    return wantarray ? (0,0) : 0 if ! @$sub;
    return wantarray ?  ()  : -1 if ! @$str;

    my @subWt = grep _ignorableAtLevel($_,$lev),
		map $self->getWt($_), @$sub;

    my(@strWt,@strPt);
    my $count = 0;
    for (my $i = 0; $i < @$str; $i++) {
	my $go_ahead = 0;

	my @tmp = grep _ignorableAtLevel($_,$lev), $self->getWt($str->[$i]);
	$go_ahead += length $str->[$i];

	# /*XXX*/ still broken.
	# index("e\x{300}", "e") should be 'no match' at level 2 or higher
	# as "e\x{300}" is a *single* grapheme cluster and not equal to "e".

	# go ahead as far as we find a combining character;
	while ($i + 1 < @$str &&
	      (! defined $str->[$i+1] || $comb->{ $str->[$i+1] }) ) {
	    $i++;
	    next if ! defined $str->[$i];
	    $go_ahead += length $str->[$i];
	    push @tmp,
		grep _ignorableAtLevel($_,$lev), $self->getWt($str->[$i]);
	}

	push @strWt, @tmp;
	push @strPt, ($count) x @tmp;
	$count += $go_ahead;

	while (@strWt >= @subWt) {
	    if (_eqArray(\@strWt, \@subWt, $lev)) {
		my $pos = $strPt[0];
		return wantarray ? ($pos, $count-$pos) : $pos;
	    }
	    shift @strWt;
	    shift @strPt;
	}
    }
    return wantarray ? () : -1;
}

##
## bool _eqArray(arrayref, arrayref, level)
##
sub _eqArray($$$)
{
    my $a   = shift; # length $a >= length $b;
    my $b   = shift;
    my $lev = shift;
    for my $v (0..$lev-1) {
	for my $c (0..@$b-1){
	    return if $a->[$c][$v] != $b->[$c][$v];
	}
    }
    return 1;
}


##
## bool _ignorableAtLevel(CE, level)
##
sub _ignorableAtLevel($$)
{
    my $ce = shift;
    return unless defined $ce;
    my $lv = shift;
    return ! grep { ! $ce->[$_] } 0..$lv-1;
}


##
## string sortkey = getSortKey(string arg)
##
sub getSortKey
{
    my $self = shift;
    my $lev  = $self->{level};
    my $rCE  = $self->splitCE(shift); # get an arrayref
    my $ver9 = $self->{UCA_Version} > 8;
    my $sht  = $self->{isShift};

    # weight arrays
    my (@buf, $last_is_variable);

    foreach my $ce (@$rCE) {
	my @t = $self->getWt($ce);
	if ($sht && $ver9) {
	    if (@t == 1 && $t[0][0] == 0) {
		if ($t[0][1] == 0 && $t[0][2] == 0) {
		    $last_is_variable = 1;
		} else {
		    next if $last_is_variable;
		}
	    } else {
		$last_is_variable = 0;
	    }
	}
	push @buf, @t;
    }

    # make sort key
    my @ret = ([],[],[],[]);
    foreach my $v (0..$lev-1) {
	foreach my $b (@buf) {
	    push @{ $ret[$v] }, $b->[$v] if $b->[$v];
	}
    }
    foreach (@{ $self->{backwards} }) {
	my $v = $_ - 1;
	@{ $ret[$v] } = reverse @{ $ret[$v] };
    }

    # modification of tertiary weights
    if ($self->{upper_before_lower}) {
	foreach (@{ $ret[2] }) {
	    if    (0x8 <= $_ && $_ <= 0xC) { $_ -= 6 } # lower
	    elsif (0x2 <= $_ && $_ <= 0x6) { $_ += 6 } # upper
	    elsif ($_ == 0x1C)             { $_ += 1 } # square upper
	    elsif ($_ == 0x1D)             { $_ -= 1 } # square lower
	}
    }
    if ($self->{katakana_before_hiragana}) {
	foreach (@{ $ret[2] }) {
	    if    (0x0F <= $_ && $_ <= 0x13) { $_ -= 2 } # katakana
	    elsif (0x0D <= $_ && $_ <= 0x0E) { $_ += 5 } # hiragana
	}
    }
    join "\0\0", map pack('n*', @$_), @ret;
}


##
## int compare = cmp(string a, string b)
##
sub cmp { $_[0]->getSortKey($_[1]) cmp $_[0]->getSortKey($_[2]) }
sub eq  { $_[0]->getSortKey($_[1]) eq  $_[0]->getSortKey($_[2]) }
sub ne  { $_[0]->getSortKey($_[1]) ne  $_[0]->getSortKey($_[2]) }
sub lt  { $_[0]->getSortKey($_[1]) lt  $_[0]->getSortKey($_[2]) }
sub le  { $_[0]->getSortKey($_[1]) le  $_[0]->getSortKey($_[2]) }
sub gt  { $_[0]->getSortKey($_[1]) gt  $_[0]->getSortKey($_[2]) }
sub ge  { $_[0]->getSortKey($_[1]) ge  $_[0]->getSortKey($_[2]) }

##
## list[strings] sorted = sort(list[strings] arg)
##
sub sort {
    my $obj = shift;
    return
	map { $_->[1] }
	    sort{ $a->[0] cmp $b->[0] }
		map [ $obj->getSortKey($_), $_ ], @_;
}


sub derivCE_9 {
    my $u = shift;
    my $base =
        (0x4E00 <= $u && $u <= 0x9FA5) # CJK
	    ? 0xFB40 :
        (0x3400 <= $u && $u <= 0x4DB5 || 0x20000 <= $u && $u <= 0x2A6D6)
	    ? 0xFB80 : 0xFBC0;

    my $aaaa = $base + ($u >> 15);
    my $bbbb = ($u & 0x7FFF) | 0x8000;
    return
	pack(VCE_FORMAT, NON_VAR, $aaaa, Min2, Min3, $u),
	pack(VCE_FORMAT, NON_VAR, $bbbb,    0,    0, $u);
}

sub derivCE_8 {
    my $code = shift;
    my $aaaa =  0xFF80 + ($code >> 15);
    my $bbbb = ($code & 0x7FFF) | 0x8000;
    return
	pack(VCE_FORMAT, NON_VAR, $aaaa, 2, 1, $code),
	pack(VCE_FORMAT, NON_VAR, $bbbb, 0, 0, $code);
}

sub broken_derivCE { # NG
    my $code = shift;
    my $aaaa = 0xFFC2 + ($code >> 15);
    my $bbbb = $code & 0x7FFF | 0x1000;
    return
	pack(VCE_FORMAT, NON_VAR, $aaaa, 2, 1, $code),
	pack(VCE_FORMAT, NON_VAR, $bbbb, 0, 0, $code);
}

##
## "hhhh hhhh hhhh" to (dddd, dddd, dddd)
##
sub _getHexArray { map hex, $_[0] =~ /([0-9a-fA-F]+)/g }

#
# $code must be in Hangul syllable.
# Check it before you enter here.
#
sub _decompHangul {
    my $code = shift;
    my $SIndex = $code - 0xAC00;
    my $LIndex = int( $SIndex / 588);
    my $VIndex = int(($SIndex % 588) / 28);
    my $TIndex =      $SIndex % 28;
    return (
	0x1100 + $LIndex,
	0x1161 + $VIndex,
	$TIndex ? (0x11A7 + $TIndex) : (),
    );
}

1;
__END__

=head1 NAME

Unicode::Collate - Unicode Collation Algorithm

=head1 SYNOPSIS

  use Unicode::Collate;

  #construct
  $Collator = Unicode::Collate->new(%tailoring);

  #sort
  @sorted = $Collator->sort(@not_sorted);

  #compare
  $result = $Collator->cmp($a, $b); # returns 1, 0, or -1.

=head1 DESCRIPTION

=head2 Constructor and Tailoring

The C<new> method returns a collator object.

   $Collator = Unicode::Collate->new(
      UCA_Version => $UCA_Version,
      alternate => $alternate,
      backwards => $levelNumber, # or \@levelNumbers
      entry => $element,
      normalization  => $normalization_form,
      ignoreName => qr/$ignoreName/,
      ignoreChar => qr/$ignoreChar/,
      katakana_before_hiragana => $bool,
      level => $collationLevel,
      overrideCJK => \&overrideCJK,
      overrideHangul => \&overrideHangul,
      preprocess => \&preprocess,
      rearrange => \@charList,
      table => $filename,
      undefName => qr/$undefName/,
      undefChar => qr/$undefChar/,
      upper_before_lower => $bool,
   );
   # if %tailoring is false (i.e. empty),
   # $Collator should do the default collation.

=over 4

=item UCA_Version

If the version number of the older UCA is given,
the older behavior of that version is emulated on collating.
If omitted, the return value of C<UCA_Version()> is used.

The supported version: 8 or 9.

B<This parameter may be removed in the future version,
as switching the algorithm would affect the performance.>

=item alternate

-- see 3.2.2 Variable Weighting, UTR #10.

(the title in UCA version 8: Alternate Weighting)

This key allows to alternate weighting for variable collation elements,
which are marked with an ASTERISK in the table
(NOTE: Many punction marks and symbols are variable in F<allkeys.txt>).

   alternate => 'blanked', 'non-ignorable', 'shifted', or 'shift-trimmed'.

These names are case-insensitive.
By default (if specification is omitted), 'shifted' is adopted.

   'Blanked'        Variable elements are ignorable at levels 1 through 3;
                    considered at the 4th level.

   'Non-ignorable'  Variable elements are not reset to ignorable.

   'Shifted'        Variable elements are ignorable at levels 1 through 3
                    their level 4 weight is replaced by the old level 1 weight.
                    Level 4 weight for Non-Variable elements is 0xFFFF.

   'Shift-Trimmed'  Same as 'shifted', but all FFFF's at the 4th level
                    are trimmed.

=item backwards

-- see 3.1.2 French Accents, UTR #10.

     backwards => $levelNumber or \@levelNumbers

Weights in reverse order; ex. level 2 (diacritic ordering) in French.
If omitted, forwards at all the levels.

=item entry

-- see 3.1 Linguistic Features; 3.2.1 File Format, UTR #10.

Overrides a default order or defines additional collation elements

  entry => <<'ENTRIES', # use the UCA file format
00E6 ; [.0861.0020.0002.00E6] [.08B1.0020.0002.00E6] # ligature <ae> as <a><e>
0063 0068 ; [.0893.0020.0002.0063]      # "ch" in traditional Spanish
0043 0068 ; [.0893.0020.0008.0043]      # "Ch" in traditional Spanish
ENTRIES

=item ignoreName

=item ignoreChar

-- see Completely Ignorable, 3.2.2 Variable Weighting, UTR #10.

Makes the entry in the table completely ignorable;
i.e. as if the weights were zero at all level.

E.g. when 'a' and 'e' are ignorable,
'element' is equal to 'lament' (or 'lmnt').

=item level

-- see 4.3 Form a sort key for each string, UTR #10.

Set the maximum level.
Any higher levels than the specified one are ignored.

  Level 1: alphabetic ordering
  Level 2: diacritic ordering
  Level 3: case ordering
  Level 4: tie-breaking (e.g. in the case when alternate is 'shifted')

  ex.level => 2,

If omitted, the maximum is the 4th.

=item normalization

-- see 4.1 Normalize each input string, UTR #10.

If specified, strings are normalized before preparation of sort keys
(the normalization is executed after preprocess).

As a form name, one of the following names must be used.

  'C'  or 'NFC'  for Normalization Form C
  'D'  or 'NFD'  for Normalization Form D
  'KC' or 'NFKC' for Normalization Form KC
  'KD' or 'NFKD' for Normalization Form KD

If omitted, the string is put into Normalization Form D.

If C<undef> is passed explicitly as the value for this key,
any normalization is not carried out (this may make tailoring easier
if any normalization is not desired).

see B<CAVEAT>.

=item overrideCJK

-- see 7.1 Derived Collation Elements, UTR #10.

By default, mapping of CJK Unified Ideographs
uses the Unicode codepoint order.
But the mapping of CJK Unified Ideographs may be overrided.

ex. CJK Unified Ideographs in the JIS code point order.

  overrideCJK => sub {
      my $u = shift;             # get a Unicode codepoint
      my $b = pack('n', $u);     # to UTF-16BE
      my $s = your_unicode_to_sjis_converter($b); # convert
      my $n = unpack('n', $s);   # convert sjis to short
      [ $n, 0x20, 0x2, $u ];     # return the collation element
  },

ex. ignores all CJK Unified Ideographs.

  overrideCJK => sub {()}, # CODEREF returning empty list

   # where ->eq("Pe\x{4E00}rl", "Perl") is true
   # as U+4E00 is a CJK Unified Ideograph and to be ignorable.

If C<undef> is passed explicitly as the value for this key,
weights for CJK Unified Ideographs are treated as undefined.
But assignment of weight for CJK Unified Ideographs
in table or L<entry> is still valid.

=item overrideHangul

-- see 7.1 Derived Collation Elements, UTR #10.

By default, Hangul Syllables are decomposed into Hangul Jamo.
But the mapping of Hangul Syllables may be overrided.

This tag works like L<overrideCJK>, so see there for examples.

If you want to override the mapping of Hangul Syllables,
the Normalization Forms D and KD are not appropriate
(they will be decomposed before overriding).

If C<undef> is passed explicitly as the value for this key,
weight for Hangul Syllables is treated as undefined
without decomposition into Hangul Jamo.
But definition of weight for Hangul Syllables
in table or L<entry> is still valid.

=item preprocess

-- see 5.1 Preprocessing, UTR #10.

If specified, the coderef is used to preprocess
before the formation of sort keys.

ex. dropping English articles, such as "a" or "the".
Then, "the pen" is before "a pencil".

     preprocess => sub {
           my $str = shift;
           $str =~ s/\b(?:an?|the)\s+//gi;
           $str;
        },

=item rearrange

-- see 3.1.3 Rearrangement, UTR #10.

Characters that are not coded in logical order and to be rearranged.
By default,

    rearrange => [ 0x0E40..0x0E44, 0x0EC0..0x0EC4 ],

If you want to disallow any rearrangement,
pass C<undef> or C<[]> (a reference to an empty list)
as the value for this key.

B<According to the version 9 of UCA, this parameter shall not be used;
but it is not warned at present.>

=item table

-- see 3.2 Default Unicode Collation Element Table, UTR #10.

You can use another element table if desired.
The table file must be in your C<lib/Unicode/Collate> directory.

By default, the file C<lib/Unicode/Collate/allkeys.txt> is used.

If C<undef> is passed explicitly as the value for this key,
no file is read (but you can define collation elements via L<entry>).

A typical way to define a collation element table
without any file of table:

   $onlyABC = Unicode::Collate->new(
       table => undef,
       entry => << 'ENTRIES',
0061 ; [.0101.0020.0002.0061] # LATIN SMALL LETTER A
0041 ; [.0101.0020.0008.0041] # LATIN CAPITAL LETTER A
0062 ; [.0102.0020.0002.0062] # LATIN SMALL LETTER B
0042 ; [.0102.0020.0008.0042] # LATIN CAPITAL LETTER B
0063 ; [.0103.0020.0002.0063] # LATIN SMALL LETTER C
0043 ; [.0103.0020.0008.0043] # LATIN CAPITAL LETTER C
ENTRIES
    );

=item undefName

=item undefChar

-- see 6.3.4 Reducing the Repertoire, UTR #10.

Undefines the collation element as if it were unassigned in the table.
This reduces the size of the table.
If an unassigned character appears in the string to be collated,
the sort key is made from its codepoint
as a single-character collation element,
as it is greater than any other assigned collation elements
(in the codepoint order among the unassigned characters).
But, it'd be better to ignore characters
unfamiliar to you and maybe never used.

=item katakana_before_hiragana

=item upper_before_lower

-- see 6.6 Case Comparisons; 7.3.1 Tertiary Weight Table, UTR #10.

By default, lowercase is before uppercase
and hiragana is before katakana.

If the tag is made true, this is reversed.

B<NOTE>: These tags simplemindedly assume
any lowercase/uppercase or hiragana/katakana distinctions
should occur in level 3, and their weights at level 3
should be same as those mentioned in 7.3.1, UTR #10.
If you define your collation elements which violates this,
these tags doesn't work validly.

=back

=head2 Methods for Collation

=over 4

=item C<@sorted = $Collator-E<gt>sort(@not_sorted)>

Sorts a list of strings.

=item C<$result = $Collator-E<gt>cmp($a, $b)>

Returns 1 (when C<$a> is greater than C<$b>)
or 0 (when C<$a> is equal to C<$b>)
or -1 (when C<$a> is lesser than C<$b>).

=item C<$result = $Collator-E<gt>eq($a, $b)>

=item C<$result = $Collator-E<gt>ne($a, $b)>

=item C<$result = $Collator-E<gt>lt($a, $b)>

=item C<$result = $Collator-E<gt>le($a, $b)>

=item C<$result = $Collator-E<gt>gt($a, $b)>

=item C<$result = $Collator-E<gt>ge($a, $b)>

They works like the same name operators as theirs.

   eq : whether $a is equal to $b.
   ne : whether $a is not equal to $b.
   lt : whether $a is lesser than $b.
   le : whether $a is lesser than $b or equal to $b.
   gt : whether $a is greater than $b.
   ge : whether $a is greater than $b or equal to $b.

=item C<$sortKey = $Collator-E<gt>getSortKey($string)>

-- see 4.3 Form a sort key for each string, UTR #10.

Returns a sort key.

You compare the sort keys using a binary comparison
and get the result of the comparison of the strings using UCA.

   $Collator->getSortKey($a) cmp $Collator->getSortKey($b)

      is equivalent to

   $Collator->cmp($a, $b)

=item C<$sortKeyForm = $Collator-E<gt>viewSortKey($string)>

   use Unicode::Collate;
   my $c = Unicode::Collate->new();
   print $c->viewSortKey("Perl"),"\n";

   # output:
   # [0B67 0A65 0B7F 0B03 | 0020 0020 0020 0020 | 0008 0002 0002 0002 | FFFF FFFF FFFF FFFF]
   #  Level 1               Level 2               Level 3               Level 4

    (If C<UCA_Version> is 8, the output is slightly different.)

=item C<$position = $Collator-E<gt>index($string, $substring)>

=item C<($position, $length) = $Collator-E<gt>index($string, $substring)>

-- see 6.8 Searching, UTR #10.

If C<$substring> matches a part of C<$string>, returns
the position of the first occurrence of the matching part in scalar context;
in list context, returns a two-element list of
the position and the length of the matching part.

B<Notice> that the length of the matching part may differ from
the length of C<$substring>.

B<Note> that the position and the length are counted on the string
after the process of preprocess, normalization, and rearrangement.
Therefore, in case the specified string is not binary equal to
the preprocessed/normalized/rearranged string, the position and the length
may differ form those on the specified string. But it is guaranteed
that, if matched, it returns a non-negative value as C<$position>.

If C<$substring> does not match any part of C<$string>,
returns C<-1> in scalar context and
an empty list in list context.

e.g. you say

  my $Collator = Unicode::Collate->new( normalization => undef, level => 1 );
  my $str = "Ich mu\x{00DF} studieren.";
  my $sub = "m\x{00FC}ss";
  my $match;
  if (my($pos,$len) = $Collator->index($str, $sub)) {
      $match = substr($str, $pos, $len);
  }

and get C<"mu\x{00DF}"> in C<$match> since C<"mu>E<223>C<">
is primary equal to C<"m>E<252>C<ss">. 

=back

=head2 Other Methods

=over 4

=item C<%old_tailoring = $Collator-E<gt>change(%new_tailoring)>

Change the value of specified keys and returns the changed part.

    $Collator = Unicode::Collate->new(level => 4);

    $Collator->eq("perl", "PERL"); # false

    %old = $Collator->change(level => 2); # returns (level => 4).

    $Collator->eq("perl", "PERL"); # true

    $Collator->change(%old); # returns (level => 2).

    $Collator->eq("perl", "PERL"); # false

Not all C<(key,value)>s are allowed to be changed.
See also C<@Unicode::Collate::ChangeOK> and C<@Unicode::Collate::ChangeNG>.

In the scalar context, returns the modified collator
(but it is B<not> a clone from the original).

    $Collator->change(level => 2)->eq("perl", "PERL"); # true

    $Collator->eq("perl", "PERL"); # true; now max level is 2nd.

    $Collator->change(level => 4)->eq("perl", "PERL"); # false

=item UCA_Version

Returns the version number of Unicode Technical Standard 10
this module consults.

=item Base_Unicode_Version

Returns the version number of the Unicode Standard
this module is based on.

=back

=head2 EXPORT

None by default.

=head2 TODO

Unicode::Collate has not been ported to EBCDIC.  The code mostly would
work just fine but a decision needs to be made: how the module should
work in EBCDIC?  Should the low 256 characters be understood as
Unicode or as EBCDIC code points?  Should one be chosen or should
there be a way to do either?  Or should such translation be left
outside the module for the user to do, for example by using
Encode::from_to()?
(or utf8::unicode_to_native()/utf8::native_to_unicode()?)

=head2 CAVEAT

Use of the C<normalization> parameter requires
the B<Unicode::Normalize> module.

If you need not it (say, in the case when you need not
handle any combining characters),
assign C<normalization =E<gt> undef> explicitly.

-- see 6.5 Avoiding Normalization, UTR #10.

=head2 Conformance Test

The Conformance Test for the UCA is provided
in L<http://www.unicode.org/reports/tr10/CollationTest.html>
and L<http://www.unicode.org/reports/tr10/CollationTest.zip>

For F<CollationTest_SHIFTED.txt>,
a collator via C<Unicode::Collate-E<gt>new( )> should be used;
for F<CollationTest_NON_IGNORABLE.txt>, a collator via
C<Unicode::Collate-E<gt>new(alternate =E<gt> "non-ignorable", level =E<gt> 3)>.

B<Unicode::Normalize is required to try this test.>

=head2 BUGS

C<index()> is an experimental method and
its return value may be unreliable.
The correct implementation for C<index()> must be based
on Locale-Sensitive Support: Level 3 in UTR #18,
F<Unicode Regular Expression Guidelines>.

See also 4.2 Locale-Dependent Graphemes in UTR #18.

=head1 AUTHOR

SADAHIRO Tomoyuki, E<lt>SADAHIRO@cpan.orgE<gt>

  http://homepage1.nifty.com/nomenclator/perl/

  Copyright(C) 2001-2002, SADAHIRO Tomoyuki. Japan. All rights reserved.

  This library is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item http://www.unicode.org/reports/tr10/

Unicode Collation Algorithm - UTR #10

=item http://www.unicode.org/reports/tr10/allkeys.txt

The Default Unicode Collation Element Table

=item http://www.unicode.org/reports/tr10/CollationTest.html
http://www.unicode.org/reports/tr10/CollationTest.zip

The latest versions of the conformance test for the UCA

=item http://www.unicode.org/reports/tr15/

Unicode Normalization Forms - UAX #15

=item http://www.unicode.org/reports/tr18

Unicode Regular Expression Guidelines - UTR #18

=item L<Unicode::Normalize>

=back

=cut
