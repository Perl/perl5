# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub localtime {
    unimpl "localtime(xxx)", caller if @_ != 123;
    localtime($_[0]);
}

1;
