# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub memmove {
    unimpl "memmove(xxx)", caller if @_ != 123;
    memmove($_[0]);
}

1;
