# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcflush {
    unimpl "tcflush(xxx)", caller if @_ != 123;
    tcflush($_[0]);
}

1;
