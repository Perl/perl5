####################################################################
package MLDBM::Serializer::FreezeThaw;
BEGIN { @MLDBM::Serializer::FreezeThaw::ISA = qw(MLDBM::Serializer) }

use FreezeThaw;

sub serialize {
    return FreezeThaw::freeze($_[1]);
}

sub deserialize {
    my ($obj) = FreezeThaw::thaw($_[1]);
    return $obj;
}

1;
