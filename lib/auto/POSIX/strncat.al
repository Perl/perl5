# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strncat {
    unimpl "strncat(xxx)", caller if @_ != 123;
    strncat($_[0]);
}

1;
