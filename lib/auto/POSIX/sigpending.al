# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigpending {
    unimpl "sigpending(xxx)", caller if @_ != 123;
    sigpending($_[0]);
}

1;
