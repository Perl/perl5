# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getpwuid {
    usage "getpwuid(uid)", caller if @_ != 1;
    getpwuid($_[0]);
}

1;
