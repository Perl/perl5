# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fpathconf {
    unimpl "fpathconf(xxx)", caller if @_ != 123;
    fpathconf($_[0]);
}

1;
