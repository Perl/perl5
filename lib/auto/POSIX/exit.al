# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub exit {
    unimpl "exit(xxx)", caller if @_ != 123;
    exit($_[0]);
}

1;
