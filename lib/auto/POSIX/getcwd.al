# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getcwd {
    unimpl "getcwd(xxx)", caller if @_ != 123;
    getcwd($_[0]);
}

1;
