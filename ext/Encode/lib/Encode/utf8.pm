package Encode::utf8;
use strict;
our $VERSION = do {my @r=(q$Revision: 0.30 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';
# package to allow long-hand
#   $octets = encode( utf8 => $string );
#

__PACKAGE__->Define(qw(UTF-8 utf8));

sub decode
{
    my ($obj,$octets,$chk) = @_;
    my $str = Encode::decode_utf8($octets);
    if (defined $str)
    {
	$_[1] = '' if $chk;
	return $str;
    }
    return undef;
}

sub encode
{
    my ($obj,$string,$chk) = @_;
    my $octets = Encode::encode_utf8($string);
    $_[1] = '' if $chk;
    return $octets;
}
1;
__END__
