# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub clock {
    unimpl "clock(xxx)", caller if @_ != 123;
    clock($_[0]);
}

1;
