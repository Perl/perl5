Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Resources.t - Demonstrate Resources
#

use Mac::Resources;
use Mac::Memory;
require "StandardFile.pl";

$file = $ARGV[0] || StandardFile::GetFile();
$res = OpenResFile($file) || die "$^E";

print "Types: ", Count1Types(), "\n\n";

for ($types = Count1Types(); $types; --$types) {
	$type = Get1IndType($types);
	print "Resources of type “$type”: ", Count1Resources($type), "\n";
	for ($rsrcs = Count1Resources($type); $rsrcs; --$rsrcs) {
		$rsrc = Get1IndResource($type, $rsrcs);
		($id, $type, $name) = GetResInfo($rsrc);
		printf("%4s %6d %s\n", $type, $id, $name);
	}
}

CloseResFile($res);
