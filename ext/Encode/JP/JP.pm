package Encode::JP;
BEGIN {
    if (ord("A") == 193) {
	die "Encode::JP not supported on EBCDIC\n";
    }
}
use Encode;
our $VERSION = '0.02';
use XSLoader;
XSLoader::load('Encode::JP',$VERSION);

use Encode::JP::JIS;
use Encode::JP::ISO_2022_JP;

1;
__END__
