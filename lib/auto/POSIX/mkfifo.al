# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub mkfifo {
    unimpl "mkfifo(xxx)", caller if @_ != 123;
    mkfifo($_[0]);
}

1;
