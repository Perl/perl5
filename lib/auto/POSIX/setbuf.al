# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setbuf {
    unimpl "setbuf(xxx)", caller if @_ != 123;
    setbuf($_[0]);
}

1;
