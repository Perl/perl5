# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getgrnam {
    usage "getgrnam(name)", caller if @_ != 1;
    getgrnam($_[0]);
}

1;
