# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub cfgetispeed {
    unimpl "cfgetispeed(xxx)", caller if @_ != 123;
    cfgetispeed($_[0]);
}

1;
