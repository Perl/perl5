# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub printf {
    usage "printf(pattern, args...)", caller if @_ < 1;
    printf STDOUT @_;
}

1;
