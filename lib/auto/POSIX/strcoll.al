# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strcoll {
    unimpl "strcoll(xxx)", caller if @_ != 123;
    strcoll($_[0]);
}

1;
