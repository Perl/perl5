# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigdelset {
    unimpl "sigdelset(xxx)", caller if @_ != 123;
    sigdelset($_[0]);
}

1;
