# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcflow {
    unimpl "tcflow(xxx)", caller if @_ != 123;
    tcflow($_[0]);
}

1;
