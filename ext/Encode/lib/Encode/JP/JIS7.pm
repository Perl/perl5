package Encode::JP::JIS7;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Encode;
for my $name ('7bit-jis', 'iso-2022-jp', 'iso-2022-jp-1'){
    my $h2z     = ($name eq '7bit-jis')    ? 0 : 1;
    my $jis0212 = ($name eq 'iso-2022-jp') ? 0 : 1;
    
    $Encode::Encoding{$name} =  
        bless {
               Name      =>   $name,
               h2z       =>   $h2z,
               jis0212   =>   $jis0212,
              } => __PACKAGE__;
}

sub name { shift->{'Name'} }
sub new_sequence { $_[0] };

use Encode::CJKConstants qw(:all);

#
# decode is identical for all 2022 variants
#

sub decode
{
    my ($obj,$str,$chk) = @_;
    jis_euc(\$str);
    return Encode::decode('euc-jp', $str, $chk);
}

#
# encode is different
#

sub encode
{
    require Encode::JP::H2Z;
    my ($obj,$str,$chk) = @_;
    my ($h2z, $jis0212) = @$obj{qw(h2z jis0212)};
    my $result = Encode::encode('euc-jp', $str, $chk);
    $h2z and &Encode::JP::H2Z::h2z(\$result);
    euc_jis(\$result, $jis0212);
    return $result;
}


# JIS<->EUC

sub jis_euc {
    my $r_str = shift;
    $$r_str =~ s(
		 ($RE{JIS_0212}|$RE{JIS_0208}|$RE{ISO_ASC}|$RE{JIS_KANA})
		 ([^\e]*)
		 )
    {
	my ($esc, $str) = ($1, $2);
	if ($esc !~ /$RE{ISO_ASC}/o) {
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
    my $jis0212 = shift;
    $$r_str =~ s{
	((?:$RE{EUC_C})+|(?:$RE{EUC_KANA})+|(?:$RE{EUC_0212})+)
	}{
	    my $str = $1;
	    my $esc = 
		( $str =~ tr/\x8E//d ) ? $ESC{KANA} :
		    ( $str =~ tr/\x8F//d ) ? $ESC{JIS_0212} :
			$ESC{JIS_0208};
	    if ($esc eq $ESC{JIS_0212} && !$jis0212){
		# fallback to '?'
		$str =~ tr/\xA1-\xFE/\x3F/;
	    }else{
		$str =~ tr/\xA1-\xFE/\x21-\x7E/;
	    }
	    $esc . $str . $ESC{ASC};
	}geox;
    $$r_str =~
	s/\Q$ESC{ASC}\E
	    (\Q$ESC{KANA}\E|\Q$ESC{JIS_0212}\E|\Q$ESC{JIS_0208}\E)/$1/gox;
    $$r_str;
}

1;
__END__


=head1 NAME

Encode::JP::JIS7 -- internally used by Encode::JP

=cut
