# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getpid {
    usage "getpid()", caller if @_ != 0;
    $$;
}

1;
