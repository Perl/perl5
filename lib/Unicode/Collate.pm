package Unicode::Collate;

use 5.006;
use strict;
use warnings;
use Carp;
use Lingua::KO::Hangul::Util;
require Exporter;

our $VERSION = '0.07';
our $PACKAGE = __PACKAGE__;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ();
our @EXPORT_OK = ();
our @EXPORT = ();

(our $Path = $INC{'Unicode/Collate.pm'}) =~ s/\.pm$//;
our $KeyFile = "allkeys.txt";

our %Combin; # combining class from Unicode::Normalize

use constant Min2      => 0x20;   # minimum weight at level 2
use constant Min3      => 0x02;   # minimum weight at level 3
use constant UNDEFINED => 0xFF80; # special value for undefined CE

##
## constructor
##
sub new
{
  my $class = shift;
  my $self = bless { @_ }, $class;

  # alternate
  $self->{alternate} = 
     ! exists  $self->{alternate} ? 'shifted' :
     ! defined $self->{alternate} ? '' : $self->{alternate};

  # collation level
  $self->{level} ||= $self->{alternate} =~ /shift/ ? 4 : 3;

  # normalization form
  $self->{normalization} = 'D' if ! exists $self->{normalization};

  eval "use Unicode::Normalize;" if defined $self->{normalization};

  $self->{normalize} = 
    ! defined $self->{normalization}        ? undef :
    $self->{normalization} =~ /^(?:NF)?C$/  ? \&NFC :
    $self->{normalization} =~ /^(?:NF)?D$/  ? \&NFD :
    $self->{normalization} =~ /^(?:NF)?KC$/ ? \&NFKC :
    $self->{normalization} =~ /^(?:NF)?KD$/ ? \&NFKD :
    croak "$PACKAGE unknown normalization form name: $self->{normalization}";

  *Combin = \%Unicode::Normalize::Combin if $self->{normalize} && ! %Combin;

  # backwards
  $self->{backwards} ||= [];
  $self->{backwards} = [ $self->{backwards} ] if ! ref $self->{backwards};

  # rearrange
  $self->{rearrange} ||= []; # maybe not U+0000 (an ASCII)
  $self->{rearrange} = [ $self->{rearrange} ] if ! ref $self->{rearrange};

  # open the table file
  my $file = defined $self->{table} ? $self->{table} : $KeyFile;
  open my $fk, "<$Path/$file" or croak "File does not exist at $Path/$file";

  while(<$fk>){
    next if /^\s*#/;
    if(/^\s*\@/){
       if(/^\@version\s*(\S*)/){
         $self->{version} ||= $1;
       }
       elsif(/^\@alternate\s+(.*)/){
         $self->{alternate} ||= $1;
       }
       elsif(/^\@backwards\s+(.*)/){
         push @{ $self->{backwards} }, $1;
       }
       elsif(/^\@rearrange\s+(.*)/){
         push @{ $self->{rearrange} }, _getHexArray($1);
       }
       next;
    }
    $self->parseEntry($_);
  }
  close $fk;
  if($self->{entry}){
    $self->parseEntry($_) foreach split /\n/, $self->{entry};
  }

  # keys of $self->{rearrangeHash} are $self->{rearrange}.
  $self->{rearrangeHash} = {};
  @{ $self->{rearrangeHash} }{ @{ $self->{rearrange} } } = ();

  return $self;
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

  # get name
  $name = $1 if $line =~ s/#\s*(.*)//;
  return if defined $self->{undefName} && $name =~ /$self->{undefName}/;

  # get element
  my($e, $k) = split /;/, $line;
  my @e = _getHexArray($e);
  $ele = pack('U*', @e);
  return if defined $self->{undefChar} && $ele =~ /$self->{undefChar}/;

  # get sort key
  if(
     defined $self->{ignoreName} && $name =~ /$self->{ignoreName}/ ||
     defined $self->{ignoreChar} && $ele  =~ /$self->{ignoreChar}/
  )
  {
     $self->{ignored}{$ele} = 1;
     $self->{entries}{$ele} = 1; # true
  }
  else
  {
    foreach my $arr ($k =~ /\[(\S+)\]/g) {
      my $var = $arr =~ /\*/;
      push @key, $self->getCE( $var, _getHexArray($arr) );
    }
    $self->{entries}{$ele} = \@key;
  }
  $self->{maxlength}{ord $ele} = scalar @e if @e > 1;
}


##
## list to collation element
##
sub getCE
{
  my $self = shift;
  my $var  = shift;
  my @c    = @_;

  $self->{alternate} eq 'blanked' ?
     $var ? [0,0,0] : [ @c[0..2] ] :
  $self->{alternate} eq 'non-ignorable' ? [ @c[0..2] ] :
  $self->{alternate} eq 'shifted' ?
    $var ? [0,0,0,$c[0] ] : [ @c[0..2], $c[0]+$c[1]+$c[2] ? 0xFFFF : 0 ] :
  $self->{alternate} eq 'shift-trimmed' ?
    $var ? [0,0,0,$c[0] ] : [ @c[0..2], 0 ] :
   \@c;
}

##
## to debug
##
sub viewSortKey
{
  my $self = shift;
  my $key  = $self->getSortKey(@_);
  my $view = join " ", map sprintf("%04X", $_), unpack 'n*', $key;
  $view =~ s/ ?0000 ?/|/g;
  "[$view]";
}

##
## sort key
##
sub getSortKey
{
  my $self = shift;
  my $code = $self->{preprocess};
  my $norm = $self->{normalize};
  my $ent  = $self->{entries};
  my $ign  = $self->{ignored};
  my $max  = $self->{maxlength};
  my $lev  = $self->{level};
  my $cjk  = $self->{overrideCJK};
  my $hang = $self->{overrideHangul};
  my $rear = $self->{rearrangeHash};

  my $str = ref $code ? &$code(shift) : shift;
  $str = &$norm($str) if ref $norm;

  my(@src, @buf);
  @src = unpack('U*', $str);

  # rearrangement
  for(my $i = 0; $i < @src; $i++)
  {
     ($src[$i], $src[$i+1]) = ($src[$i+1], $src[$i])
        if $rear->{ $src[$i] };
     $i++;
  }

  for(my $i = 0; $i < @src; $i++)
  {
    my $ch;
    my $u  = $src[$i];

  # non-characters
    next if $u < 0 || 0x10FFFF < $u     # out of range
         || 0xD800 < $u && $u < 0xDFFF; # unpaired surrogates
    my $four = $u & 0xFFFF; 
    next if $four == 0xFFFE || $four == 0xFFFF;

    if($max->{$u}) # contract
    {
      for(my $j = $max->{$u}; $j >= 1; $j--)
      { 
        next unless $i+$j-1 < @src;
        $ch = pack 'U*', @src[$i .. $i+$j-1];
        $i += $j-1, last if $ent->{$ch};
      }
    }
    else {  $ch = pack('U', $u) }

    if(%Combin && defined $ch) # with Combining Char
    {
      for(my $j = $i+1; $j < @src && $Combin{ $src[$j] }; $j++)
      {
        my $comb = pack 'U', $src[$j];
        next if ! $ent->{ $ch.$comb };
        $ch .= $comb;
        splice(@src, $j, 1);
        last;
      }
    }

    next if !defined $ch || $ign->{$ch};   # ignored

    push @buf,
      $ent->{$ch}
        ? @{ $ent->{$ch} }
        : _isHangul($u)
          ? $hang
            ? &$hang($u)
            : map(@{ $ent->{pack('U', $_)} }, decomposeHangul($u))
          : _isCJK($u)
            ? $cjk ? &$cjk($u) : map($self->getCE(0,@$_), _CJK($u))
            : map($self->getCE(0,@$_), _derivCE($u));
  }

  # make sort key
  my @ret = ([],[],[],[]);
  foreach my $v (0..$lev-1){
    foreach my $b (@buf){
      push @{ $ret[$v] }, $b->[$v] if $b->[$v];
    }
  }
  foreach (@{ $self->{backwards} }){
    my $v = $_ - 1;
    @{ $ret[$v] } = reverse @{ $ret[$v] };
  }

  # modification of tertiary weights
  if($self->{upper_before_lower}){
    foreach (@{ $ret[2] }){
      if   (0x8 <= $_ && $_ <= 0xC){ $_ -= 6 } # lower
      elsif(0x2 <= $_ && $_ <= 0x6){ $_ += 6 } # upper
      elsif($_ == 0x1C)            { $_ += 1 } # square upper
      elsif($_ == 0x1D)            { $_ -= 1 } # square lower
    }
  }
  if($self->{katakana_before_hiragana}){
    foreach (@{ $ret[2] }){
      if   (0x0F <= $_ && $_ <= 0x13){ $_ -= 2 } # katakana
      elsif(0x0D <= $_ && $_ <= 0x0E){ $_ += 5 } # hiragana
    }
  }
  join "\0\0", map pack('n*', @$_), @ret;
}


##
## cmp
##
sub cmp
{
  my $obj = shift;
  my $a   = shift;
  my $b   = shift;
  $obj->getSortKey($a) cmp $obj->getSortKey($b);
}

##
## sort
##
sub sort
{
  my $obj = shift;

  map { $_->[1] }
  sort{ $a->[0] cmp $b->[0] }
  map [ $obj->getSortKey($_), $_ ], @_;
}

##
## Derived CE
##
sub _derivCE
{
  my $code = shift;
  my $a = UNDEFINED + ($code >> 15); # ok
  my $b = ($code & 0x7FFF) | 0x8000; # ok
# my $a = 0xFFC2 + ($code >> 15);    # ng
# my $b = $code & 0x7FFF | 0x1000;   # ng
  $b ? ([$a,2,1,$code],[$b,0,0,$code]) : [$a,2,1,$code];
}

##
## "hhhh hhhh hhhh" to (dddd, dddd, dddd)
##
sub _getHexArray
{
  my $str = shift;
  map hex(), $str =~ /([0-9a-fA-F]+)/g;
}

##
##  CJK Unified Ideographs
##
sub _isCJK
{
  my $u = shift;
  return 0x3400 <= $u && $u <= 0x4DB5  
      || 0x4E00 <= $u && $u <= 0x9FA5  
#      || 0x20000 <= $u && $u <= 0x2A6D6;
}

##
##  CJK Unified Ideographs
##
sub _CJK
{
  my $u = shift;
  $u > 0xFFFF ? _derivCE($u) : [$u,0x20,0x02,$u];
}

##
## Hangul Syllables
##
sub _isHangul
{
  my $code = shift;
  return 0xAC00 <= $code && $code <= 0xD7A3;
}

1;
__END__

=head1 NAME

Unicode::Collate - use UCA (Unicode Collation Algorithm)

=head1 SYNOPSIS

  use Unicode::Collate;

  #construct
  $UCA = Unicode::Collate->new(%tailoring);

  #sort
  @sorted = $UCA->sort(@not_sorted);

  #compare
  $result = $UCA->cmp($a, $b); # returns 1, 0, or -1. 

=head1 DESCRIPTION

=head2 Constructor and Tailoring

   $UCA = Unicode::Collate->new(
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
   # if %tailoring is false (empty),
   # $UCA should do the default collation.

=over 4

=item alternate

-- see 3.2.2 Alternate Weighting, UTR #10.

   alternate => 'shifted', 'blanked', 'non-ignorable', or 'shift-trimmed'.

By default (if specification is omitted), 'shifted' is adopted.

=item backwards

-- see 3.1.2 French Accents, UTR #10.

     backwards => $levelNumber or \@levelNumbers

Weights in reverse order; ex. level 2 (diacritic ordering) in French.
If omitted, forwards at all the levels.

=item entry

-- see 3.1 Linguistic Features; 3.2.1 File Format, UTR #10.

Overrides a default order or adds a new element

  entry => <<'ENTRIES', # use the UCA file format
00E6 ; [.0861.0020.0002.00E6] [.08B1.0020.0002.00E6] # ligature <ae> as <a e>
0063 0068 ; [.0893.0020.0002.0063]      # "ch" in traditional Spanish
0043 0068 ; [.0893.0020.0008.0043]      # "Ch" in traditional Spanish
ENTRIES

=item ignoreName

=item ignoreChar

-- see Completely Ignorable, 3.2.2 Alternate Weighting, UTR #10.

Ignores the entry in the table.
If an ignored collation element appears in the string to be collated,
it is ignored as if the element had been deleted from there.

E.g. when 'a' and 'e' are ignored,
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

=item normalization

-- see 4.1 Normalize each input string, UTR #10.

If specified, strings are normalized before preparation sort keys
(the normalization is executed after preprocess).

As a form name, one of the following names must be used.

  'C'  or 'NFC'  for Normalization Form C
  'D'  or 'NFD'  for Normalization Form D
  'KC' or 'NFKC' for Normalization Form KC
  'KD' or 'NFKD' for Normalization Form KD

If omitted, the string is put into Normalization Form D.

If undefined explicitly (as C<normalization =E<gt> undef>),
any normalization is not carried out (this may make tailoring easier
if any normalization is not desired).

see B<CAVEAT>.

=item overrideCJK

=item overrideHangul

-- see 7.1 Derived Collation Elements, UTR #10.

By default, mapping of CJK Unified Ideographs
uses the Unicode codepoint order
and Hangul Syllables are decomposed into Hangul Jamo.

The mapping of CJK Unified Ideographs
or Hangul Syllables may be overrided.

ex. CJK Unified Ideographs in the JIS codepoint order.

  overrideCJK => sub {
    my $u = shift;               # get unicode codepoint
    my $b = pack('n', $u);       # to UTF-16BE
    my $s = your_unicode_to_sjis_converter($b); # convert
    my $n = unpack('n', $s);     # convert sjis to short
    [ $n, 1, 1 ];                # return collation element
  },

If you want to override the mapping of Hangul Syllables,
the Normalization Forms D and KD are not appropriate
(they will be decomposed before overriding).

=item preprocess

-- see 5.1 Preprocessing, UTR #10.

If specified, the coderef is used to preprocess
before the formation of sort keys.

ex. dropping English articles, such as "a" or "the". 
Then, "the pen" is before "a pencil".

     preprocess => sub {
           my $str = shift;
           $str =~ s/\b(?:an?|the)\s+//g;
           $str;
        },

=item rearrange

-- see 3.1.3 Rearrangement, UTR #10.

Characters that are not coded in logical order and to be rearranged.
By default, 

    rearrange => [ 0x0E40..0x0E44, 0x0EC0..0x0EC4 ],

=item table

-- see 3.2 Default Unicode Collation Element Table, UTR #10.

You can use another element table if desired.
The table file must be in your C<lib/Unicode/Collate> directory.

By default, the file C<lib/Unicode/Collate/allkeys.txt> is used.

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

If the parameter is true, this is reversed.

=back

=head2 Other methods

=over 4

=item C<@sorted = $UCA-E<gt>sort(@not_sorted)>

Sorts a list of strings.

=item C<$result = $UCA-E<gt>cmp($a, $b)>

Returns 1 (when C<$a> is greater than C<$b>)
or 0 (when C<$a> is equal to C<$b>)
or -1 (when C<$a> is lesser than C<$b>).

=item C<$sortKey = $UCA-E<gt>getSortKey($string)>

-- see 4.3 Form a sort key for each string, UTR #10.

Returns a sort key.

You compare the sort keys using a binary comparison
and get the result of the comparison of the strings using UCA.

   $UCA->getSortKey($a) cmp $UCA->getSortKey($b)

      is equivalent to

   $UCA->cmp($a, $b)

=back

=head2 EXPORT

None by default.

=head2 CAVEAT

Use of the C<normalization> parameter requires
the B<Unicode::Normalize> module.

If you need not it (e.g. in the case when you need not
handle any combining characters),
assign C<normalization =E<gt> undef> explicitly.

=head1 AUTHOR

SADAHIRO Tomoyuki, E<lt>SADAHIRO@cpan.orgE<gt>

  http://homepage1.nifty.com/nomenclator/perl/

  Copyright(C) 2001, SADAHIRO Tomoyuki. Japan. All rights reserved.

  This program is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<Lingua::KO::Hangul::Util>

utility functions for Hangul Syllables

=item L<Unicode::Normalize>

normalized forms of Unicode text

=item Unicode Collation Algorithm - Unicode TR #10

http://www.unicode.org/unicode/reports/tr10/

=back

=cut
