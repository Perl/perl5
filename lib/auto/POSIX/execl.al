# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub execl {
    unimpl "execl(xxx)", caller if @_ != 123;
    execl($_[0]);
}

1;
