# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ttyname {
    unimpl "ttyname(xxx)", caller if @_ != 123;
    ttyname($_[0]);
}

1;
