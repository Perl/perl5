# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub _exit {
    unimpl "_exit(xxx)", caller if @_ != 123;
    _exit($_[0]);
}

1;
