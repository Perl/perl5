#!perl

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir '../lib/Archive/Tar/t/src' if -d '../lib/Archive/Tar/t/src';
    }
}

unlink 'long/bar.tar', 'long/foo.tgz', 'short/bar.tar', 'short/foo.tgz';
