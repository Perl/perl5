# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigaddset {
    unimpl "sigaddset(xxx)", caller if @_ != 123;
    sigaddset($_[0]);
}

1;
