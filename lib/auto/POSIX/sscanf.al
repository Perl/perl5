# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sscanf {
    unimpl "sscanf(xxx)", caller if @_ != 123;
    sscanf($_[0]);
}

1;
