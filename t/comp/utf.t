#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
    if ($ENV{PERL_CORE_MINITEST}) {
	print "1..0 # Skip: no dynamic loading on miniperl, no threads\n";
	exit 0;
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
}

BEGIN { require "./test.pl"; }

plan(tests => 18);

my $BOM = chr(0xFEFF);

sub test {
    my ($enc, $tag, $bom) = @_;
    open(UTF_PL, ">:raw:encoding($enc)", "utf$$.pl")
	or die "utf.pl($enc,$tag,$bom): $!";
    print UTF_PL $BOM if $bom;
    print UTF_PL "$tag\n";
    close(UTF_PL);
    my $got = do "./utf$$.pl";
    is($got, $tag);
}

for my $bom (0, 1) {
    for my $enc (qw(utf16le utf16be utf8)) {
	for my $value (123, 1234, 12345) {
	    test($enc, $value, $bom);
	}
    }
}

END {
    1 while unlink "utf$$.pl";
}
