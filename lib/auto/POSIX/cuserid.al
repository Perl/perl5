# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub cuserid {
    unimpl "cuserid(xxx)", caller if @_ != 123;
    cuserid($_[0]);
}

1;
