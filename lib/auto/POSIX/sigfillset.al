# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigfillset {
    unimpl "sigfillset(xxx)", caller if @_ != 123;
    sigfillset($_[0]);
}

1;
