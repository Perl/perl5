# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub getgroups {
    usage "getgroups()", caller if @_ != 0;
    local(%seen) = ();
    grep(!%seen{$_}++, split(' ', $) ));
}

1;
