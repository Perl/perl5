# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub system {
    usage "system(command)", caller if @_ != 1;
    system($_[0]);
}

1;
