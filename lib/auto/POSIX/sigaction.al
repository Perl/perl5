# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigaction {
    unimpl "sigaction(xxx)", caller if @_ != 123;
    sigaction($_[0]);
}

1;
