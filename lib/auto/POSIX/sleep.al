# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub sleep {
    unimpl "sleep(xxx)", caller if @_ != 123;
    sleep($_[0]);
}

1;
