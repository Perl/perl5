# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strxfrm {
    unimpl "strxfrm(xxx)", caller if @_ != 123;
    strxfrm($_[0]);
}

1;
