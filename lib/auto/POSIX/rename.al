# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub rename {
    usage "rename(oldfilename, newfilename)", caller if @_ != 2;
    rename($_[0], $_[1]);
}

1;
