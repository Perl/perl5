# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub vprintf {
    unimpl "vprintf(xxx)", caller if @_ != 123;
    vprintf($_[0]);
}

1;
