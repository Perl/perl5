# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fflush {
    unimpl "fflush(xxx)", caller if @_ != 123;
    fflush($_[0]);
}

1;
