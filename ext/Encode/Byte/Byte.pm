package Encode::Byte;
use Encode;
our $VERSION = do { my @r = (q$Revision: 0.96 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

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
  iso-8859-1    latin1
  iso-8859-2    latin2
  iso-8859-3    latin3
  iso-8859-4    latin4
  iso-8859-5    latin
  iso-8859-6    latin
  iso-8859-7
  iso-8859-8
  iso-8859-9    latin5
  iso-8859-10   latin6
  iso-8859-11
  (iso-8859-12 is nonexistent)
  iso-8859-13   latin7
  iso-8859-14   latin8
  iso-8859-15   latin9
  iso-8859-16   latin10

  koi8-f
  koi8-r
  koi8-u

  viscii        # ASCII + vietnamese

  cp1250        WinLatin2
  cp1251        WinCyrillic
  cp1252        WinLatin1
  cp1253        WinGreek
  cp1254        WinTurkiskh
  cp1255        WinHebrew
  cp1256        WinArabic
  cp1257        WinBaltic
  cp1258        WinVietnamese
  # all cp* are also available as ibm-* and ms-*

  maccentraleuropean  
  maccroatian
  macroman
  maccyrillic
  macromanian
  macdingbats       
  macsami
  macgreek 
  macthai
  macicelandic    
  macturkish
  macukraine

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 SEE ALSO

L<Encode>

=cut
