# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub cfsetospeed {
    unimpl "cfsetospeed(xxx)", caller if @_ != 123;
    cfsetospeed($_[0]);
}

1;
