package Encode::CN::2022_CN;
use Encode::CN;
use base 'Encode::Encoding';

use strict;

our $VERSION = do { my @r = (q$Revision: 0.99 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# Just for the time being, we implement jis-7bit
# encoding via EUC

my $canon = 'iso-2022-cn';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

sub name { return $_[0]->{name}; }

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $res = $str;
    iso_euc(\$res);
    return Encode::decode('euc-cn', $res, $chk);
}

sub encode
{
    my ($obj,$str,$chk) = @_;
    my $res = Encode::encode('euc-cn', $str, $chk);
    euc_iso(\$res);
    return $res;
}

use Encode::CJKConstants qw(:all);

# ISO<->EUC

sub iso_euc {
    my $r_str = shift;
    $$r_str =~ s(
		 ($RE{GB_2312}|$RE{ISO_ASC})
		 ([^\e]*)
		 )
    {
	my ($esc, $str) = ($1, $2);
	if ($esc !~ /$RE{ISO_ASC}/o) {
	    $str =~ tr/\x21-\x7e/\xa1-\xfe/;
	}
	$str;
    }geox;
    $$r_str;
}

sub euc_iso{
    my $r_str = shift;
    $$r_str =~ s{
	($RE{EUC_C}+)
	}{
	    my $str = $1;
	    my $esc = $ESC{GB_2312};
	    $str =~ tr/\xA1-\xFE/\x21-\x7E/;
	    $esc . $str . $ESC{ASC};
	}geox;
    $$r_str =~
	s/\Q$ESC{ASC}\E(\Q$ESC{GB_2312}\E)/$1/gox;
    $$r_str;
}

1;
__END__
