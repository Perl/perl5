# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tzname {
    unimpl "tzname(xxx)", caller if @_ != 123;
    tzname($_[0]);
}

1;
