#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

print "1..10\n";

my $grk = "grk$$";
my $utf = "utf$$";
my $fail1 = "fail$$";

if (open(GRK, ">$grk")) {
    # alpha beta gamma in ISO 8859-7
    print GRK "\xe1\xe2\xe3";
    close GRK;
}

{
    use Encode;
    open(my $i,'<:encoding(iso-8859-7)',$grk);
    print "ok 1\n";
    open(my $o,'>:utf8',$utf);
    print "ok 2\n";
    print $o readline($i);
    print "ok 3\n";
    close($o);
    close($i);
}

if (open(UTF, "<$utf")) {
    # alpha beta gamma in UTF-8 Unicode (0x3b1 0x3b2 0x3b3)
    print "not " unless <UTF> eq "\xce\xb1\xce\xb2\xce\xb3";
    print "ok 4\n";
    close UTF;
}

{
    use Encode;
    open(my $i,'<:utf8',$utf);
    print "ok 5\n";
    open(my $o,'>:encoding(iso-8859-7)',$grk);
    print "ok 6\n";
    print $o readline($i);
    print "ok 7\n";
    close($o);
    close($i);
}

if (open(GRK, "<$grk")) {
    print "not " unless <GRK> eq "\xe1\xe2\xe3";
    print "ok 8\n";
    close GRK;
}

$SIG{__WARN__} = sub {$warn = $_[0]};

if (open(FAIL, ">:encoding(NoneSuch)", $fail1)) {
    print "not ok 9 # Open should fail\n";
} else {
    print "ok 9\n";
}
if (!defined $warn) {
    print "not ok 10 # warning is undef\n";
} elsif ($warn =~ /^Cannot find encoding "NoneSuch" at/) {
    print "ok 10\n";
} else {
    print "not ok 10 # warning is '$warn'";
}

END {
    unlink($grk, $utf, $fail1);
}
