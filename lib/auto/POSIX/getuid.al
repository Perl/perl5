# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getuid {
    usage "getuid()", caller if @_ != 0;
    $<;
}

1;
