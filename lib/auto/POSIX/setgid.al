# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub setgid {
    unimpl "setgid(xxx)", caller if @_ != 123;
    setgid($_[0]);
}

1;
