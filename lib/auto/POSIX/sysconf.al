# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sysconf {
    unimpl "sysconf(xxx)", caller if @_ != 123;
    sysconf($_[0]);
}

1;
