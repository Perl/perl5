#!./perl

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
}

my $tmp = "via$$";

use Test::More tests => 11;

my $fh;
my $a = join("", map { chr } 0..255) x 10;
my $b;

BEGIN { use_ok('MIME::QuotedPrint'); }

ok( open($fh,">Via(MIME::QuotedPrint)", $tmp), 'open QuotedPrint for output');
ok( (print $fh $a), "print to output file");
ok( close($fh), 'close output file');

ok( open($fh,"<Via(MIME::QuotedPrint)", $tmp), 'open QuotedPrint for input');
{ local $/; $b = <$fh> }
ok( close($fh), "close input file");

is($a, $b, 'compare original data with filtered version');


{
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings = join '', @_ };

    use warnings 'layer';
    ok( ! open($fh,">Via(Unknown::Module)", $tmp), 'open Via Unknown::Module will fail');
    like( $warnings, qr/^Cannot find package 'Unknown::Module'/,  'warn about unknown package' );

    $warnings = '';
    no warnings 'layer';
    ok( ! open($fh,">Via(Unknown::Module)", $tmp), 'open Via Unknown::Module will fail');
    is( $warnings, "",  "don't warn about unknown package" );
}    

END {
    1 while unlink $tmp;
}
