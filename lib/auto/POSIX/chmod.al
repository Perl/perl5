# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub chmod {
    usage "chmod(filename, mode)", caller if @_ != 2;
    chmod($_[0], $_[1]);
}

1;
