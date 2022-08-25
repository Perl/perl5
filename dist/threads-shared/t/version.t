use strict;
use warnings;
use Test::More;

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use threads::shared;

# test that the version documented in threads.pm pod matches
# that of the code.

open my $fh, "<", $INC{"threads/shared.pm"}
    or die qq(Failed to open '$INC{"threads/shared.pm"}': $!);
my $file= do { local $/; <$fh> };
close $fh;
my $pod_version = 0; 
if ($file=~/This document describes threads::shared version (\d.\d+)/) {
    $pod_version = $1;
}
is($pod_version, $threads::shared::VERSION,
   "Check that pod and \$threads::shared::VERSION match");
done_testing();
