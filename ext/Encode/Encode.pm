package Encode;

$VERSION = 0.01;

require DynaLoader;
require Exporter;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK =
    qw(
       bytes_to_utf8
       utf8_to_bytes
       chars_to_utf8
       utf8_to_chars
       utf8_to_chars_check
       bytes_to_chars
       chars_to_bytes
       from_to
       is_utf8
       on_utf8
       off_utf8
       utf_to_utf
       encodings
      );

bootstrap Encode ();

=pod

=head1 NAME

Encode - character encodings

=head2 TERMINOLOGY

=over

=item *

I<char>: a character in the range 0..maxint (at least 2**32-1)

=item *

I<byte>: a character in the range 0..255

=back

The marker [INTERNAL] marks Internal Implementation Details, in
general meant only for those who think they know what they are doing,
and such details may change in future releases.

=head2 bytes

=over 4

=item *

        bytes_to_utf8(STRING [, FROM])

The bytes in STRING are recoded in-place into UTF-8.  If no FROM is
specified the bytes are expected to be encoded in US-ASCII or ISO
8859-1 (Latin 1).  Returns the new size of STRING, or C<undef> if
there's a failure.

[INTERNAL] Also the UTF-8 flag of STRING is turned on.

=item *

        utf8_to_bytes(STRING [, TO [, CHECK]])

The UTF-8 in STRING is decoded in-place into bytes.  If no TO encoding
is specified the bytes are expected to be encoded in US-ASCII or ISO
8859-1 (Latin 1).  Returns the new size of STRING, or C<undef> if
there's a failure.

What if there are characters > 255?  What if the UTF-8 in STRING is
malformed?  See L</"Handling Malformed Data">.

[INTERNAL] The UTF-8 flag of STRING is not checked.

=back

=head2 chars

=over 4

=item *

        chars_to_utf8(STRING)

The chars in STRING are encoded in-place into UTF-8.  Returns the new
size of STRING, or C<undef> if there's a failure.

No assumptions are made on the encoding of the chars.  If you want to
assume that the chars are Unicode and to trap illegal Unicode
characters, you must use C<from_to('Unicode', ...)>.

[INTERNAL] Also the UTF-8 flag of STRING is turned on.

=over 4

=item *

        utf8_to_chars(STRING)

The UTF-8 in STRING is decoded in-place into chars.  Returns the new
size of STRING, or C<undef> if there's a failure.

If the UTF-8 in STRING is malformed C<undef> is returned, and also an
optional lexical warning (category utf8) is given.

[INTERNAL] The UTF-8 flag of STRING is not checked.

=item *

        utf8_to_chars_check(STRING [, CHECK])

(Note that special naming of this interface since a two-argument
utf8_to_chars() has different semantics.)

The UTF-8 in STRING is decoded in-place into chars.  Returns the new
size of STRING, or C<undef> if there is a failure.

If the UTF-8 in STRING is malformed?  See L</"Handling Malformed Data">.

[INTERNAL] The UTF-8 flag of STRING is not checked.

=back

=head2 chars With Encoding

=over 4

=item *

        chars_to_utf8(STRING, FROM [, CHECK])

The chars in STRING encoded in FROM are recoded in-place into UTF-8.
Returns the new size of STRING, or C<undef> if there's a failure.

No assumptions are made on the encoding of the chars.  If you want to
assume that the chars are Unicode and to trap illegal Unicode
characters, you must use C<from_to('Unicode', ...)>.

[INTERNAL] Also the UTF-8 flag of STRING is turned on.

=item *

        utf8_to_chars(STRING, TO [, CHECK])

The UTF-8 in STRING is decoded in-place into chars encoded in TO.
Returns the new size of STRING, or C<undef> if there's a failure.

If the UTF-8 in STRING is malformed?  See L</"Handling Malformed Data">.

[INTERNAL] The UTF-8 flag of STRING is not checked.

=item *

	bytes_to_chars(STRING, FROM [, CHECK])

The bytes in STRING encoded in FROM are recoded in-place into chars.
Returns the new size of STRING in bytes, or C<undef> if there's a
failure.

If the mapping is impossible?  See L</"Handling Malformed Data">.

=item *

	chars_to_bytes(STRING, TO [, CHECK])

The chars in STRING are recoded in-place to bytes encoded in TO.
Returns the new size of STRING in bytes, or C<undef> if there's a
failure.

If the mapping is impossible?  See L</"Handling Malformed Data">.

=item *

        from_to(STRING, FROM, TO [, CHECK])

The chars in STRING encoded in FROM are recoded in-place into TO.
Returns the new size of STRING, or C<undef> if there's a failure.

If mapping between the encodings is impossible?
See L</"Handling Malformed Data">.

[INTERNAL] If TO is UTF-8, also the UTF-8 flag of STRING is turned on.

=back

=head2 Testing For UTF-8

=over 4

=item *

        is_utf8(STRING [, CHECK])

[INTERNAL] Test whether the UTF-8 flag is turned on in the STRING.
If CHECK is true, also checks the data in STRING for being
well-formed UTF-8.  Returns true if successful, false otherwise.

=back

=head2 Toggling UTF-8-ness

=over 4

=item *

        on_utf8(STRING)

[INTERNAL] Turn on the UTF-8 flag in STRING.  The data in STRING is
B<not> checked for being well-formed UTF-8.  Do not use unless you
B<know> that the STRING is well-formed UTF-8.  Returns the previous
state of the UTF-8 flag (so please don't test the return value as
I<not> success or failure), or C<undef> if STRING is not a string.

=item *

        off_utf8(STRING)

[INTERNAL] Turn off the UTF-8 flag in STRING.  Do not use frivolously.
Returns the previous state of the UTF-8 flag (so please don't test the
return value as I<not> success or failure), or C<undef> if STRING is
not a string.

=back

=head2 UTF-16 and UTF-32 Encodings

=over 4

=item *

        utf_to_utf(STRING, FROM, TO [, CHECK])

The data in STRING is converted from Unicode Transfer Encoding FROM to
Unicode Transfer Encoding TO.  Both FROM and TO may be any of the
following tags (case-insensitive, with or without 'utf' or 'utf-' prefix):

        tag             meaning

        '7'             UTF-7
        '8'             UTF-8
        '16be'          UTF-16 big-endian
        '16le'          UTF-16 little-endian
        '16'            UTF-16 native-endian
        '32be'          UTF-32 big-endian
        '32le'          UTF-32 little-endian
        '32'            UTF-32 native-endian

UTF-16 is also known as UCS-2, 16 bit or 2-byte chunks, and UTF-32 as
UCS-4, 32-bit or 4-byte chunks.  Returns the new size of STRING, or
C<undef> is there's a failure.

If FROM is UTF-8 and the UTF-8 in STRING is malformed?  See
L</"Handling Malformed Data">.

[INTERNAL] Even if CHECK is true and FROM is UTF-8, the UTF-8 flag of
STRING is not checked.  If TO is UTF-8, also the UTF-8 flag of STRING is
turned on.  Identical FROM and TO are fine.

=back

=head2 Handling Malformed Data

If CHECK is not set, C<undef> is returned.  If the data is supposed to
be UTF-8, an optional lexical warning (category utf8) is given.  If
CHECK is true but not a code reference, dies.  If CHECK is a code
reference, it is called with the arguments

	(MALFORMED_STRING, STRING_FROM_SO_FAR, STRING_TO_SO_FAR)

Two return values are expected from the call: the string to be used in
the result string in place of the malformed section, and the length of
the malformed section in bytes.

=cut

sub bytes_to_utf8 {
    &_bytes_to_utf8;
}

sub utf8_to_bytes {
    &_utf8_to_bytes;
}

sub chars_to_utf8 {
    &C_to_utf8;
}

sub utf8_to_chars {
    &_utf8_to_chars;
}

sub utf8_to_chars_check {
    &_utf8_to_chars_check;
}

sub bytes_to_chars {
    &_bytes_to_chars;
}

sub chars_to_bytes {
    &_chars_to_bytes;
}

sub is_utf8 {
    &_is_utf8;
}

sub on_utf8 {
    &_on_utf8;
}

sub off_utf8 {
    &_off_utf8;
}

sub utf_to_utf {
    &_utf_to_utf;
}

use Carp;

sub from_to
{
 my ($string,$from,$to,$check) = @_;
 my $f = __PACKAGE__->getEncoding($from);
 croak("Unknown encoding '$from'") unless $f;
 my $t = __PACKAGE__->getEncoding($to);
 croak("Unknown encoding '$to'") unless $t;
 my $uni = $f->toUnicode($string,$check);
 return undef if ($check && length($string));
 $string = $t->fromUnicode($uni,$check);
 return undef if ($check && length($uni));
 return length($_[0] = $string);
}

my %encoding = ( Unicode      => bless({},'Encode::Unicode'),
                 'iso10646-1' => bless({},'Encode::iso10646_1'),
               );

sub encodings
{
 my ($class) = @_;
 foreach my $dir (@INC)
  {
   if (opendir(my $dh,"$dir/Encode"))
    {
     while (defined(my $name = readdir($dh)))
      {
       if ($name =~ /^(.*)\.enc$/)
        {
         next if exists $encoding{$1};
         $encoding{$1} = "$dir/$name";
        }
      }
     closedir($dh);
    }
  }
 return keys %encoding;
}

sub loadEncoding
{
 my ($class,$name,$file) = @_;
 if (open(my $fh,$file))
  {
   my $type;
   while (1)
    {
     my $line = <$fh>;
     $type = substr($line,0,1);
     last unless $type eq '#';
    }
   $class .= ('::'.(($type eq 'E') ? 'Escape' : 'Table'));
   return $class->read($fh,$name,$type);
  }
 else
  {
   return undef;
  }
}

sub getEncoding
{
 my ($class,$name) = @_;
 my $enc;
 unless (ref($enc = $encoding{$name}))
  {
   $enc = $class->loadEncoding($name,$enc) if defined $enc;
   unless (ref($enc))
    {
     foreach my $dir (@INC)
      {
       last if ($enc = $class->loadEncoding($name,"$dir/Encode/$name.enc"));
      }
    }
   $encoding{$name} = $enc;
  }
 return $enc;
}

package Encode::Unicode;

# Dummy package that provides the encode interface

sub name { 'Unicode' }

sub toUnicode   { $_[1] }

sub fromUnicode { $_[1] }

package Encode::Table;

sub read
{
 my ($class,$fh,$name,$type) = @_;
 my $rep = $class->can("rep_$type");
 my ($def,$sym,$pages) = split(/\s+/,scalar(<$fh>));
 my @touni;
 my %fmuni;
 my $count = 0;
 $def = hex($def);
 while ($pages--)
  {
   my $line = <$fh>;
   chomp($line);
   my $page = hex($line);
   my @page;
   my $ch = $page * 256;
   for (my $i = 0; $i < 16; $i++)
    {
     my $line = <$fh>;
     for (my $j = 0; $j < 16; $j++)
      {
       my $val = hex(substr($line,0,4,''));
       if ($val || !$ch)
        {
         my $uch = chr($val);
         push(@page,$uch);
         $fmuni{$uch} = $ch;
         $count++;
        }
       else
        {
         push(@page,undef);
        }
       $ch++;
      }
    }
   $touni[$page] = \@page;
  }

 return bless {Name  => $name,
               Rep   => $rep,
               ToUni => \@touni,
               FmUni => \%fmuni,
               Def   => $def,
               Num   => $count,
              },$class;
}

sub name { shift->{'Name'} }

sub rep_S { 'C' }

sub rep_D { 'n' }

sub rep_M { ($_[0] > 255) ? 'n' : 'C' }

sub representation
{
 my ($obj,$ch) = @_;
 $ch = 0 unless @_ > 1;
 $obj-{'Rep'}->($ch);
}

sub toUnicode
{
 my ($obj,$str,$chk) = @_;
 my $rep   = $obj->{'Rep'};
 my $touni = $obj->{'ToUni'};
 my $uni   = '';
 while (length($str))
  {
   my $ch = ord(substr($str,0,1,''));
   my $x;
   if (&$rep($ch) eq 'C')
    {
     $x = $touni->[0][$ch];
    }
   else
    {
     $x = $touni->[$ch][ord(substr($str,0,1,''))];
    }
   unless (defined $x)
    {
     last if $chk;
     # What do we do here ?
     $x = '';
    }
   $uni .= $x;
  }
 $_[1] = $str if $chk;
 return $uni;
}

sub fromUnicode
{
 my ($obj,$uni,$chk) = @_;
 my $fmuni = $obj->{'FmUni'};
 my $str   = '';
 my $def   = $obj->{'Def'};
 my $rep   = $obj->{'Rep'};
 while (length($uni))
  {
   my $ch = substr($uni,0,1,'');
   my $x  = $fmuni->{chr(ord($ch))};
   unless (defined $x)
    {
     last if ($chk);
     $x = $def;
    }
   $str .= pack(&$rep($x),$x);
  }
 $_[1] = $uni if $chk;
 return $str;
}

package Encode::iso10646_1;#

sub name { 'iso10646-1' }

sub toUnicode
{
 my ($obj,$str,$chk) = @_;
 my $uni   = '';
 while (length($str))
  {
   my $code = unpack('n',substr($str,0,2,'')) & 0xffff;
   $uni .= chr($code);
  }
 $_[1] = $str if $chk;
 return $uni;
}

sub fromUnicode
{
 my ($obj,$uni,$chk) = @_;
 my $str   = '';
 while (length($uni))
  {
   my $ch = substr($uni,0,1,'');
   my $x  = ord($ch);
   unless ($x < 32768)
    {
     last if ($chk);
     $x = 0;
    }
   $str .= pack('n',$x);
  }
 $_[1] = $uni if $chk;
 return $str;
}

package Encode::Escape;
use Carp;

sub read
{
 my ($class,$fh,$name) = @_;
 my %self = (Name => $name, Num => 0);
 while (<$fh>)
  {
   my ($key,$val) = /^(\S+)\s+(.*)$/;
   $val =~ s/^\{(.*?)\}/$1/g;
   $val =~ s/\\x([0-9a-f]{2})/chr(hex($1))/ge;
   $self{$key} = $val;
  }
 return bless \%self,$class;
}

sub name { shift->{'Name'} }

sub toUnicode
{
 croak("Not implemented yet");
}

sub fromUnicode
{
 croak("Not implemented yet");
}

1;

__END__
