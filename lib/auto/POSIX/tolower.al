# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tolower {
    usage "tolower(string)", caller if @_ != 1;
    lc($_[0]);
}

1;
