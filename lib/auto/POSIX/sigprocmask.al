# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigprocmask {
    unimpl "sigprocmask(xxx)", caller if @_ != 123;
    sigprocmask($_[0]);
}

1;
