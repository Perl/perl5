package Encoding::Unicode;
use strict;
our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use base 'Encode::Encoding';

__PACKAGE__->Define('Unicode') unless ord('A') == 65;

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $res = '';
    for (my $i = 0; $i < length($str); $i++)
    {
	$res .= chr(utf8::unicode_to_native(ord(substr($str,$i,1))));
    }
    $_[1] = '' if $chk;
    return $res;
}

sub encode
{
    my ($obj,$str,$chk) = @_;
    my $res = '';
    for (my $i = 0; $i < length($str); $i++)
    {
	$res .= chr(utf8::native_to_unicode(ord(substr($str,$i,1))));
    }
    $_[1] = '' if $chk;
    return $res;
}

1;
__END__

=head1 NAME

Encode::Unicode -- for internal use only

=cut
