# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub gmtime {
    unimpl "gmtime(xxx)", caller if @_ != 123;
    gmtime($_[0]);
}

1;
