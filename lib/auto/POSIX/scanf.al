# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub scanf {
    unimpl "scanf(xxx)", caller if @_ != 123;
    scanf($_[0]);
}

1;
