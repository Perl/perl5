# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub cfsetispeed {
    unimpl "cfsetispeed(xxx)", caller if @_ != 123;
    cfsetispeed($_[0]);
}

1;
