# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strcmp {
    unimpl "strcmp(xxx)", caller if @_ != 123;
    strcmp($_[0]);
}

1;
