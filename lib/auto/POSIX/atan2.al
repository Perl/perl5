# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub atan2 {
    usage "atan2(x,y)", caller if @_ != 2;
    atan2($_[0], $_[1]);
}

1;
