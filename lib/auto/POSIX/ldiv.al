# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub ldiv {
    unimpl "ldiv(xxx)", caller if @_ != 123;
    ldiv($_[0]);
}

1;
