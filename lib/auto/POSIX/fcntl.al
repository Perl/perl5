# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fcntl {
    usage "fcntl(filehandle, cmd, arg)", caller if @_ != 3;
    fcntl($_[0], $_[1], $_[2]);
}

1;
