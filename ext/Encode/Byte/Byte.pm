package Encode::Byte;
use Encode;
our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use XSLoader;
XSLoader::load('Encode::Byte',$VERSION);

1;
__END__

=head1 NAME

Encode::Byte - Single Byte Encodings

=head1 SYNOPSIS

    use Encode qw/encode decode/; 
    $latin1 = encode("iso-8859-1", $utf8);   # loads Encode::Byte implicitly
    $utf8  = decode("iso-8859-1", $latin1);  # ditto

=head1 ABSTRACT

This module implements various single byte encodings.  For most cases it uses
\x80-\xff (upper half) to map non-ASCII characters.  Encodings
supported are as follows.   

  Canonical   Alias		Description
  --------------------------------------------------------------------
  # ISO 8859 series
  (iso-8859-1	is in built-in)
  iso-8859-2	latin2					     [ISO]
  iso-8859-3	latin3					     [ISO]
  iso-8859-4	latin4					     [ISO]
  iso-8859-5						     [ISO]
  iso-8859-6						     [ISO]
  iso-8859-7						     [ISO]
  iso-8859-8						     [ISO]
  iso-8859-9	latin5					     [ISO]
  iso-8859-10	latin6					     [ISO]
  iso-8859-11
  (iso-8859-12 is nonexistent)
  iso-8859-13   latin7					     [ISO]
  iso-8859-14	latin8					     [ISO]
  iso-8859-15	latin9					     [ISO]
  iso-8859-16	latin10					     [ISO]

  # Cyrillic
  koi8-f					
  koi8-r						 [RFC1489]
  koi8-u						 [RFC2319]

  # Vietnamese
  viscii
  
  # all cp* are also available as ibm-*, ms-*, and windows-*
  # also see L<http://msdn.microsoft.com/workshop/author/dhtml/reference/charsets/charset4.asp>
  cp1250	WinLatin2
  cp1251	WinCyrillic
  cp1252	WinLatin1
  cp1253	WinGreek
  cp1254	WinTurkiskh
  cp1255	WinHebrew
  cp1256	WinArabic
  cp1257	WinBaltic
  cp1258	WinVietnamese

  # Macintosh
  # Also see L<http://developer.apple.com/technotes/tn/tn1150.html>
  MacCentralEurRoman
  MacCroatian
  MacRoman
  MacCyrillic
  MacRomanian
  MacSami
  MacGreek 
  MacThai
  MacIcelandic    
  MacTurkish
  MacUkrainian

  # More vendor encodings
  nextstep
  gsm0338	# used in GSM handsets
  hp-roman8

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 SEE ALSO

L<Encode>

=cut
