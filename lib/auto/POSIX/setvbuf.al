# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setvbuf {
    unimpl "setvbuf(xxx)", caller if @_ != 123;
    setvbuf($_[0]);
}

1;
