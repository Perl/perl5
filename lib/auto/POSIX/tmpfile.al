# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub tmpfile {
    unimpl "tmpfile(xxx)", caller if @_ != 123;
    tmpfile($_[0]);
}

1;
