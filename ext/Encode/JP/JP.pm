package Encode::JP;
use Encode;
our $VERSION = '0.02';
use XSLoader;
XSLoader::load('Encode::JP',$VERSION);

use Encode::JP::JIS;
use Encode::JP::ISO_2022_JP;

1;
__END__
