# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub time {
    unimpl "time(xxx)", caller if @_ != 123;
    time($_[0]);
}

1;
