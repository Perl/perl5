# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub kill {
    usage "kill(pid, sig)", caller if @_ != 2;
    kill $_[1], $_[0];
}

1;
