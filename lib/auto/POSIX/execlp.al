# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub execlp {
    unimpl "execlp(xxx)", caller if @_ != 123;
    execlp($_[0]);
}

1;
