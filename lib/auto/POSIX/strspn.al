# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strspn {
    unimpl "strspn(xxx)", caller if @_ != 123;
    strspn($_[0]);
}

1;
