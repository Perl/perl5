package Encode::JP::ISO_2022_JP;
use Encode::JP;
use Encode::JP::JIS;
use Encode::JP::H2Z;
use base 'Encode::Encoding';


my $canon = 'iso-2022-jp';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

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
