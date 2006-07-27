use Test;
use strict;
use File::Basename qw(dirname);
use File::Spec;
use Digest::SHA;

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

# David Ireland's test vector - SHA-256 digest of "a" x 536870912

# Adapted from Julius Duque's original script (t/24-ireland.tmp)
#	- modified to use state cache via dump()/load() methods

BEGIN { plan tests => 1 }

my $file = File::Spec->catfile(dirname($0), "ireland.tmp");
open(my $fh, q{>}, $file); while (<DATA>) { print $fh $_ }  close($fh);

my $data = "a" x 1000000;
my $vec = "b9045a713caed5dff3d3b783e98d1ce5778d8bc331ee4119d707072312af06a7";

my $ctx;
unless ($ctx = Digest::SHA->load($file)) {
	$ctx = Digest::SHA->new(256);
	for (1 .. 536) { $ctx->add($data) }
	$ctx->add(substr($data, 0, 870910));
	$ctx->dump($file);
}
$ctx->add("aa");
ok($ctx->hexdigest, $vec);

unlink($file);

__DATA__
alg:256
H:dd75eb45:02d4f043:06b41193:6fda751d:73064db9:787d54e1:52dc3fe0:48687dfa
block:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
blockcnt:496
lenhh:0
lenhl:0
lenlh:0
lenll:4294967280
