# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub fstat {
    usage "fstat(fd)", caller if @_ != 1;
    local(*TMP);
    open(TMP, "<&$_[0]");		# Gross.
    local(@l) = stat(TMP);
    close(TMP);
    @l;
}

1;
