# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub abort {
    unimpl "abort(xxx)", caller if @_ != 123;
    abort($_[0]);
}

1;
