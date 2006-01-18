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

	plan tests => 1 + scalar(@vec);
}

	# attempt to use an invalid algorithm, and check for failure

my $NSA = "SHA-42";	# No Such Algorithm
ok(Digest::SHA->new($NSA), undef);

	# test OO methods using first two SHA-256 vectors from NIST

my $temp = File::Spec->catfile(dirname($0), "oo.tmp");
my $file = File::Spec->canonpath($temp);
open(FILE, ">$file");
binmode(FILE);
print FILE "bcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
close(FILE);

my $ctx = Digest::SHA->new()->reset("SHA-256")->new();
$ctx->add_bits("a", 5)->add_bits("001");

my $rsp = shift(@vec);
ok($ctx->clone->add("b", "c")->b64digest, $rsp);

$rsp = shift(@vec);
open(FILE, "<$file");
binmode(FILE);
ok($ctx->addfile(*FILE)->hexdigest, $rsp);
close(FILE);
unlink($file);
