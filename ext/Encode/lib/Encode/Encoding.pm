package Encode::Encoding;
# Base class for classes which implement encodings
use strict;
our $VERSION = '0.02';

sub Define
{
    my $obj = shift;
    my $canonical = shift;
    $obj = bless { Name => $canonical },$obj unless ref $obj;
    # warn "$canonical => $obj\n";
  Encode::define_encoding($obj, $canonical, @_);
}

sub name { shift->{'Name'} }

# Temporary legacy methods
sub toUnicode    { shift->decode(@_) }
sub fromUnicode  { shift->encode(@_) }

sub new_sequence { return $_[0] }

1;
__END__
