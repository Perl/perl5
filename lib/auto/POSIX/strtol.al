# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strtol {
    unimpl "strtol(xxx)", caller if @_ != 123;
    strtol($_[0]);
}

1;
