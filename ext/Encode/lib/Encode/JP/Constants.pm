#
# $Id: Constants.pm,v 1.2 2001/05/18 05:14:38 dankogai Exp dankogai $
#

package Encode::JP::Constants;

use strict;
use vars qw($RCSID $VERSION);

$RCSID = q$Id: Constants.pm,v 1.2 2001/05/18 05:14:38 dankogai Exp dankogai $;
$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Carp;

BEGIN {
    use Exporter;
    use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(%CHARCODE %ESC %RE);
    %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK, @EXPORT ] );
}

use vars @EXPORT_OK;

my %_0208 = (
	       1978 => '\e\$\@',
	       1983 => '\e\$B',
	       1990 => '\e&\@\e\$B',
		);

%CHARCODE = (
	     UNDEF_EUC  =>     "\xa2\xae",  # во in EUC
	     UNDEF_SJIS =>     "\x81\xac",  # во in SJIS
	     UNDEF_JIS  =>     "\xa2\xf7",  # вў -- used in unicode
	     UNDEF_UNICODE  => "\x20\x20",  # вў -- used in unicode
	 );

%ESC =  (
	 JIS_0208 => "\e\$B",
	 JIS_0212 => "\e\$(D",
	 ASC      => "\e\(B",
	 KANA     => "\e\(I",
	 );

%RE =
    (
     ASCII     => '[\x00-\x7f]',
     BIN       => '[\x00-\x06\x7f\xff]',
     EUC_0212  => '\x8f[\xa1-\xfe][\xa1-\xfe]',
     EUC_C     => '[\xa1-\xfe][\xa1-\xfe]',
     EUC_KANA  => '\x8e[\xa1-\xdf]',
     JIS_0208  =>  "$_0208{1978}|$_0208{1983}|$_0208{1990}",
     JIS_0212  => "\e" . '\$\(D',
     JIS_ASC   => "\e" . '\([BJ]',     
     JIS_KANA  => "\e" . '\(I',
     SJIS_C    => '[\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]',
     SJIS_KANA => '[\xa1-\xdf]',
     UTF8      => '[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf][\x80-\xbf]'
     );

1;

