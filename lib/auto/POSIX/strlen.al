# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strlen {
    unimpl "strlen(xxx)", caller if @_ != 123;
    strlen($_[0]);
}

1;
