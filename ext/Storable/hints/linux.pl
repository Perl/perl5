# gcc -O3 (and higher) can cause Storable.xs to produce code that
# dumps core immediately in recurse.t and retrieve.t, in is_storing()
# and last_op_in_netorder(), respectively.  In both cases the cxt is
# full of junk (and according to valgrind the cxt was never stack'd,
# malloc'd or free'd).  Observed in Debian 3.0 x86, both with gccs
# 2.95.4 20011002 and 3.3.
use Config;
$self->{OPTIMIZE} = '-O2'
    if -f '/etc/debian_version' &&
       ($Config{gccversion} =~ /^2\.95\.4 20011002 / ||
        $Config{gccversion} eq '3.3');

