# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strcpy {
    unimpl "strcpy(xxx)", caller if @_ != 123;
    strcpy($_[0]);
}

1;
