# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strtok {
    unimpl "strtok(xxx)", caller if @_ != 123;
    strtok($_[0]);
}

1;
