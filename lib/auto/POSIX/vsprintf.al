# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub vsprintf {
    unimpl "vsprintf(xxx)", caller if @_ != 123;
    vsprintf($_[0]);
}

1;
