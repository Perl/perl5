# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub log {
    usage "log(x)", caller if @_ != 1;
    log($_[0]);
}

1;
