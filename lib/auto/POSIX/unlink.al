# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub unlink {
    usage "unlink(filename)", caller if @_ != 1;
    unlink($_[0]);
}

1;
