#!perl
use File::Spec;

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir '../lib/Archive/Tar/t' if -d '../lib/Archive/Tar/t';
    }
}

for my $d (qw(long short)) { 
    for my $f (qw(b bar.tar foo.tgz)) {
	unlink File::Spec->catfile('src', $d, $f);
    }
    rmdir File::Spec->catdir('src', $d);
}

rmdir 'src';

print "1..1\nok 1 - cleanup done\n";
