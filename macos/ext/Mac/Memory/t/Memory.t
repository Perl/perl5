Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Memory.t - List some statistics about the heap.
#

use Mac::Memory;

print <<END;
Stack Space: @{[StackSpace]}
Free Memory: @{[FreeMem]}
Max  Memory: @{[MaxMem]}
END

$h  = new Handle("xyzzy");
$fh = $h->open("<");

$_ = <$fh>;

print;
