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
$r = $h->open("r");

# should be "xyzzy"
print <$r>, "\n";

$w = $h->open("w");
print $w "wysiwyg";

# should be "wysiwyg"
print $h->get, "\n";

truncate $w, 0;
# should be " (0)"
printf "%s (%d)\n", $h->get, $h->size;
# should be blank
print <$r>, "\n";
# should be " (0)"
undef $w;
printf "%s (%d)\n", $h->get, $h->size;

truncate $r, 0;
# should be " (0)"
printf "%s (%d)\n", $h->get, $h->size;
__END__
