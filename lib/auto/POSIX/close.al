# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub close {
    unimpl "close(xxx)", caller if @_ != 123;
    close($_[0]);
}

1;
