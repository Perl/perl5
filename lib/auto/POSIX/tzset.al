# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tzset {
    unimpl "tzset(xxx)", caller if @_ != 123;
    tzset($_[0]);
}

1;
