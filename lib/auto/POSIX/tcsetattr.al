# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcsetattr {
    unimpl "tcsetattr(xxx)", caller if @_ != 123;
    tcsetattr($_[0]);
}

1;
