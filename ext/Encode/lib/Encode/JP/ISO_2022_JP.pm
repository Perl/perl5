package Encode::JP::ISO_2022_JP;
use Encode::JP;
use Encode::JP::JIS;
use Encode::JP::H2Z;
use base 'Encode::Encoding';

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 0.94 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $canon = 'iso-2022-jp';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

sub name { return $_[0]->{name}; }

#
# decode is identical to 7bit-jis
#

sub decode
{
    my ($obj,$str,$chk) = @_;
    return Encode::decode('7bit-jis', $str, $chk);
}

# iso-2022-jp = 7bit-jis with all x201 (Hankaku) converted to
#               x208 equivalent (Zenkaku)

sub encode
{
    my ($obj,$str,$chk) = @_;
    my $euc =  Encode::encode('euc-jp', $str, $chk);
    &Encode::JP::H2Z::h2z(\$euc);
    return &Encode::JP::JIS::euc_jis(\$euc);
}

1;
__END__
