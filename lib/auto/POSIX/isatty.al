# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub isatty {
    unimpl "isatty(xxx)", caller if @_ != 123;
    isatty($_[0]);
}

1;
