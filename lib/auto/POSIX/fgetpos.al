# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fgetpos {
    unimpl "fgetpos(xxx)", caller if @_ != 123;
    fgetpos($_[0]);
}

1;
