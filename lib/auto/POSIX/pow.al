# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub pow {
    usage "pow(x,exponent)", caller if @_ != 2;
    $_[0] ** $_[1];
}

1;
