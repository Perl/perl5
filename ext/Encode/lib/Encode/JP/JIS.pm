package Encode::JP::JIS;
use Encode::JP;
use base 'Encode::Encoding';

# Just for the time being, we implement jis-7bit
# encoding via EUC

my $canon = '7bit-jis';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $res = $str;
    jis_euc(\$res);
    return Encode::decode('euc-jp', $euc, $chk);
}

sub encode
{
    my ($obj,$str,$chk) = @_;
    my $res = Encode::encode('euc-jp', $str, $chk);
    euc_jis(\$res);
    return $res;
}

use Encode::JP::Constants qw(:all);

# JIS<->EUC

sub jis_euc {
    my $r_str = shift;
    $$r_str =~ s(
		 ($RE{JIS_0212}|$RE{JIS_0208}|$RE{JIS_ASC}|$RE{JIS_KANA})
		 ([^\e]*)
		 )
    {
	my ($esc, $str) = ($1, $2);
	if ($esc !~ /$RE{JIS_ASC}/o) {
	    $str =~ tr/\x21-\x7e/\xa1-\xfe/;
	    if ($esc =~ /$RE{JIS_KANA}/o) {
		$str =~ s/([\xa1-\xdf])/\x8e$1/og;
	    }
	    elsif ($esc =~ /$RE{JIS_0212}/o) {
		$str =~ s/([\xa1-\xfe][\xa1-\xfe])/\x8f$1/og;
	    }
	}
	$str;
    }geox;
    $$r_str;
}

sub euc_jis{
    my $r_str = shift;
    $$r_str =~ s{
	((?:$RE{EUC_C})+|(?:$RE{EUC_KANA})+|(?:$RE{EUC_0212})+)
	}{
	    my $str = $1;
	    my $esc = 
		( $str =~ tr/\x8E//d ) ? $ESC{KANA} :
		    ( $str =~ tr/\x8F//d ) ? $ESC{JIS_0212} :
			$ESC{JIS_0208};
	    $str =~ tr/\xA1-\xFE/\x21-\x7E/;
	    $esc . $str . $ESC{ASC};
	}geox;
    $$r_str =~
	s/\Q$ESC{ASC}\E
	    (\Q$ESC{KANA}\E|\Q$ESC{JIS_0212}\E|\Q$ESC{JIS_0208}\E)/$1/gox;
    $$r_str;
}

1;
__END__
