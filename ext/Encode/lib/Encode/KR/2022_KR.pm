package Encode::KR::2022_KR;
use Encode::KR;
use base 'Encode::Encoding';

use strict;

our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };


my $canon = 'iso-2022-kr';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

sub name { return $_[0]->{name}; }

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $res = $str;
    iso_euc(\$res);
    return Encode::decode('euc-kr', $res, $chk);
}

sub encode
{
    my ($obj,$str,$chk) = @_;
    my $res = Encode::encode('euc-kr', $str, $chk);
    euc_iso(\$res);
    return $res;
}

use Encode::CJKConstants qw(:all);

# ISO<->EUC

sub iso_euc{
    my $r_str = shift;
    $$r_str =~ s/$RE{'2022_KR'}//gox;  # remove the designator 
    $$r_str =~ s{                    # replace chars. in GL
     \x0e                            # between SO(\x0e) and SI(\x0f)
     ([^\x0f]*)                      # with chars. in GR
     \x0f
	}
    {
			my $out= $1; 
      $out =~ tr/\x21-\x7e/\xa1-\xfe/;
      $out;
    }geox;
    $$r_str;
}

sub euc_iso{
    my $r_str = shift;
    substr($$r_str,0,0)=$ESC{'2022_KR'};  # put the designator at the beg. 
    $$r_str =~ s{                     # move KS X 1001 chars. in GR to GL
	($RE{EUC_C}+)                       # and enclose them with SO and SI
	}{
	    my $str = $1;
	    $str =~ tr/\xA1-\xFE/\x21-\x7E/;
	    "\x0e" . $str . "\x0f";
	}geox;
    $$r_str;
}

1;
__END__
