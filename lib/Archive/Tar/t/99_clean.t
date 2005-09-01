#!perl
use File::Spec;

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir '../lib/Archive/Tar/t/src' if -d '../lib/Archive/Tar/t/src';
    }
}

for my $d (qw(long short)) { 
    for my $f (qw(b bar.tar foo.tgz)) {
	unlink File::Spec->catfile($d, $f);
    }
}

print "1..1\nok 1 - cleanup done\n";
