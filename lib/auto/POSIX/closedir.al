# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub closedir {
    usage "closedir(dirhandle)", caller if @_ != 1;
    closedir($_[0]);
    ungensym($_[0]);
}

1;
