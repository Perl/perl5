# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getpwnam {
    usage "getpwnam(name)", caller if @_ != 1;
    getpwnam($_[0]);
}

1;
