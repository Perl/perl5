# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub cfgetospeed {
    unimpl "cfgetospeed(xxx)", caller if @_ != 123;
    cfgetospeed($_[0]);
}

1;
