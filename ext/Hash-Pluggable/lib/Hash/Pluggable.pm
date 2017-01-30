package Hash::Pluggable;
use 5.025010;
use warnings;

our $VERSION = '0.01';

our %VtableRegistry;

require XSLoader;
XSLoader::load();

sub import {
    # Enable keywords in lexical scope (the choice of string isn't
    # magical, it just needs to match the one in XS)
    $^H{"Hash::Pluggable/is_enabled"} = 1;
}

sub unimport {
    # And disable our keywords!
    delete $^H{"Hash::Pluggable/is_enabled"};
}

1;

# ex: set ts=8 sts=4 sw=4 et:
