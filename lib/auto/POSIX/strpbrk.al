# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strpbrk {
    unimpl "strpbrk(xxx)", caller if @_ != 123;
    strpbrk($_[0]);
}

1;
