# NOTE:  Derived from POSIX.pm.  Changes made here will be lost.
package POSIX;

sub assert {
    usage "assert(expr)", caller if @_ != 1;
    if (!$_[0]) {
	local ($pack,$file,$line) = caller;
	die "Assertion failed at $file line $line\n";
    }
}

1;
