# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub mktime {
    unimpl "mktime(xxx)", caller if @_ != 123;
    mktime($_[0]);
}

1;
