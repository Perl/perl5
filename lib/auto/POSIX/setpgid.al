# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setpgid {
    unimpl "setpgid(xxx)", caller if @_ != 123;
    setpgid($_[0]);
}

1;
