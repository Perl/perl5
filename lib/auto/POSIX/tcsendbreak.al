# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcsendbreak {
    unimpl "tcsendbreak(xxx)", caller if @_ != 123;
    tcsendbreak($_[0]);
}

1;
