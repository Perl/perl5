# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub signal {
    unimpl "signal(xxx)", caller if @_ != 123;
    signal($_[0]);
}

1;
