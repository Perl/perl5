#!./perl -w

# Tests for the command-line switches

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

require "./test.pl";

plan(tests => 6);

my $r;

my @tmpfiles = ();
END { unlink @tmpfiles }

$r = runperl( switches => [ '-CO', '-w' ],
	      prog     => 'print chr(256)',
              stderr   => 1 );
is( $r, "\xC4\x80", '-CO: no warning on UTF-8 output' );

SKIP: {
    for my $l (qw(LC_ALL LC_CTYPE LANG)) {
	skip("cannot easily test under UTF-8 locale", 1)
	    if $ENV{$l} =~ /utf-?8/i;
    }
    $r = runperl( switches => [ '-CI', '-w' ],
		  prog     => 'print ord(<STDIN>)',
		  stderr   => 1,
		  verbose  => 1,
		  stdin    => "\xC4\x80" );
    is( $r, 256, '-CI: read in UTF-8 input' );
}

$r = runperl( switches => [ '-CE', '-w' ],
	      prog     => 'warn chr(256), qq(\n)',
              stderr   => 1 );
chomp $r;
is( $r, "\xC4\x80", '-CE: UTF-8 stderr' );

$r = runperl( switches => [ '-Co', '-w' ],
	      prog     => 'open(F, q(>out)); print F chr(256); close F',
              stderr   => 1 );
is( $r, '', '-Co: auto-UTF-8 open for output' );

push @tmpfiles, "out";

$r = runperl( switches => [ '-Ci', '-w' ],
	      prog     => 'open(F, q(<out)); print ord(<F>); close F',
              stderr   => 1 );
is( $r, 256, '-Ci: auto-UTF-8 open for input' );

$r = runperl( switches => [ '-CA', '-w' ],
	      prog     => 'print ord shift',
              stderr   => 1,
              args     => [ chr(256) ] );
is( $r, 256, '-CA: @ARGV' );

