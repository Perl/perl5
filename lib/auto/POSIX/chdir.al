# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub chdir {
    unimpl "chdir(xxx)", caller if @_ != 123;
    chdir($_[0]);
}

1;
