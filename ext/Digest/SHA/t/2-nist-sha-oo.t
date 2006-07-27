use Test;
use strict;
use integer;
use File::Basename qw(dirname);
use File::Spec;
use Digest::SHA;

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

my(@vec);

BEGIN {
	@vec = (
"ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0",
"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
	);

	plan tests => 6 + scalar(@vec);
}

	# attempt to use an invalid algorithm, and check for failure

my $NSA = "SHA-42";	# No Such Algorithm
ok(Digest::SHA->new($NSA), undef);

	# test OO methods using first two SHA-256 vectors from NIST

my $file = File::Spec->catfile(dirname($0), "oo.tmp");
open(my $fh, q{>}, $file);
binmode($fh);
print $fh "bcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
close($fh);

my $ctx = Digest::SHA->new()->reset("SHA-256")->new();
$ctx->add_bits("a", 5)->add_bits("001");

my $rsp = shift(@vec);
ok($ctx->clone->add("b", "c")->b64digest, $rsp);

$rsp = shift(@vec);

	# test addfile with bareword filehandle

open(FILE, "<$file");					## no critic
binmode(FILE);						## no critic
ok($ctx->clone->addfile(*FILE)->hexdigest, $rsp);	## no critic
close(FILE);						## no critic

	# test addfile with indirect filehandle

undef($fh); open($fh, q{<}, $file);
binmode($fh);
ok($ctx->clone->addfile($fh)->hexdigest, $rsp);
close($fh);

	# test addfile using file name instead of handle

ok($ctx->addfile($file, "b")->hexdigest, $rsp);

	# test addfile portable mode

undef($fh); open($fh, q{>}, $file);
binmode($fh);
print $fh "abc\012" x 2048;		# using UNIX newline
close($fh);

ok($ctx->new(1)->addfile($file, "p")->hexdigest,
	"d449e19c1b0b0c191294c8dc9fa2e4a6ff77fc51");

undef($fh); open($fh, q{>}, $file);
binmode($fh);
print $fh "abc\015\012" x 2048;		# using DOS/Windows newline
close($fh);

ok($ctx->new(1)->addfile($file, "p")->hexdigest,
	"d449e19c1b0b0c191294c8dc9fa2e4a6ff77fc51");

undef($fh); open($fh, q{>}, $file);
binmode($fh);
print $fh "abc\015" x 2048;		# using Apple/Mac newline
close($fh);

ok($ctx->new(1)->addfile($file, "p")->hexdigest,
	"d449e19c1b0b0c191294c8dc9fa2e4a6ff77fc51");

unlink($file);
