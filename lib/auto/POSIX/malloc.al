# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub malloc {
    unimpl "malloc(xxx)", caller if @_ != 123;
    malloc($_[0]);
}

1;
