# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigsuspend {
    unimpl "sigsuspend(xxx)", caller if @_ != 123;
    sigsuspend($_[0]);
}

1;
