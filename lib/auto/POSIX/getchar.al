# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getchar {
    usage "getchar()", caller if @_ != 0;
    getc(STDIN);
}

1;
