# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub vfprintf {
    unimpl "vfprintf(xxx)", caller if @_ != 123;
    vfprintf($_[0]);
}

1;
