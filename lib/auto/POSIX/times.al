# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub times {
    usage "times()", caller if @_ != 0;
    times();
}

1;
