# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub mbstowcs {
    unimpl "mbstowcs(xxx)", caller if @_ != 123;
    mbstowcs($_[0]);
}

1;
