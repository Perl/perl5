package Encode::CN::HZ;

use Encode::CN;
use Encode qw|encode decode|;
use base 'Encode::Encoding';

use strict;

# HZ is but escaped GB, so we implement it with the
# GB2312(raw) encoding here. Cf. RFC 1842 & 1843.

my $canon = 'hz';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $gb = Encode::find_encoding('gb2312');

    $str =~ s{~(?:(~)|\n|{([^~]*)~}|)}
             {$1 ? '~' : defined $2 ? $gb->decode($2, $chk) : ''}eg;

    return $str;
}

sub encode
{
    my ($obj,$str,$chk) = @_;
    my $gb = Encode::find_encoding('gb2312');

    $str =~ s/~/~~/g;
    $str =~ s/((?:	
	\p{InCJKCompatibility}|
	\p{InCJKCompatibilityForms}|
	\p{InCJKCompatibilityIdeographs}|
	\p{InCJKCompatibilityIdeographsSupplement}|
	\p{InCJKRadicalsSupplement}|
	\p{InCJKSymbolsAndPunctuation}|
	\p{InCJKUnifiedIdeographsExtensionA}|
	\p{InCJKUnifiedIdeographs}|
	\p{InCJKUnifiedIdeographsExtensionB}|
	\p{InEnclosedCJKLettersAndMonths}
    )+)/'~{'.$gb->encode($1, $chk).'~}'/egx;

    return $str;
}

1;
__END__
