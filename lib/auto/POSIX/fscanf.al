# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fscanf {
    unimpl "fscanf() is C-specific--use <> and regular expressions instead", caller;
    unimpl "fscanf(xxx)", caller if @_ != 123;
    fscanf($_[0]);
}

1;
