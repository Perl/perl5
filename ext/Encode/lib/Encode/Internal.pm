package Encode::Internal;
use strict;
our $VERSION = do {my @r=(q$Revision: 0.30 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use base 'Encode::Encoding';

# Dummy package that provides the encode interface but leaves data
# as UTF-X encoded. It is here so that from_to() works.

__PACKAGE__->Define('Internal');

Encode::define_alias( 'Unicode' => 'Internal' ) if ord('A') == 65;

sub decode
{
    my ($obj,$str,$chk) = @_;
  utf8::upgrade($str);
    $_[1] = '' if $chk;
    return $str;
}

*encode = \&decode;
1;
__END__
