# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sprintf {
    unimpl "sprintf(xxx)", caller if @_ != 123;
    sprintf($_[0]);
}

1;
