# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub creat {
    usage "creat(filename, mode)", caller if @_ != 2;
    &open($_[0], &O_WRONLY | &O_CREAT | &O_TRUNC, $_[2]);
}

1;
