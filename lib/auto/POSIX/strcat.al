# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strcat {
    unimpl "strcat(xxx)", caller if @_ != 123;
    strcat($_[0]);
}

1;
