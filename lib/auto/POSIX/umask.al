# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub umask {
    usage "umask(mask)", caller if @_ != 1;
    umask($_[0]);
}

1;
