# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub alarm {
    unimpl "alarm(xxx)", caller if @_ != 123;
    alarm($_[0]);
}

1;
