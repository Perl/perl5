# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub execle {
    unimpl "execle(xxx)", caller if @_ != 123;
    execle($_[0]);
}

1;
