# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub strtod {
    unimpl "strtod(xxx)", caller if @_ != 123;
    strtod($_[0]);
}

1;
