# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sigemptyset {
    unimpl "sigemptyset(xxx)", caller if @_ != 123;
    sigemptyset($_[0]);
}

1;
