# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tcgetattr {
    unimpl "tcgetattr(xxx)", caller if @_ != 123;
    tcgetattr($_[0]);
}

1;
