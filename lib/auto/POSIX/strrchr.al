# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strrchr {
    unimpl "strrchr(xxx)", caller if @_ != 123;
    strrchr($_[0]);
}

1;
