# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub rand {
    unimpl "rand(xxx)", caller if @_ != 123;
    rand($_[0]);
}

1;
