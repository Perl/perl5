# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setsid {
    unimpl "setsid(xxx)", caller if @_ != 123;
    setsid($_[0]);
}

1;
