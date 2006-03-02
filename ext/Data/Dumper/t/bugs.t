#!perl
#
# regression tests for old bugs that don't fit other categories

BEGIN {
    if ($ENV{PERL_CORE}){
	chdir 't' if -d 't';
	unshift @INC, '../lib';
	require Config; import Config;
	no warnings 'once';
	if ($Config{'extensions'} !~ /\bData\/Dumper\b/) {
	    print "1..0 # Skip: Data::Dumper was not built\n";
	    exit 0;
	}
    }
}

use strict;
use Test::More tests => 2;
use Data::Dumper;

{
    sub iterate_hash {
	my ($h) = @_;
	my $count = 0;
	$count++ while each %$h;
	return $count;
    }

    my $dumper = Data::Dumper->new( [\%ENV], ['ENV'] )->Sortkeys(1);
    my $orig_count = iterate_hash(\%ENV);
    $dumper->Dump;
    my $new_count = iterate_hash(\%ENV);
    is($new_count, $orig_count, 'correctly resets hash iterators');
}

# [perl #38612] Data::Dumper core dump in 5.8.6, fixed by 5.8.7
sub foo {
     my $s = shift;
     local $Data::Dumper::Terse = 1;
     my $c = eval Dumper($s);
     sub bar::quote { }
     bless $c, 'bar';
     my $d = Data::Dumper->new([$c]);
     $d->Freezer('quote');
     return $d->Dump;
}
foo({});
ok(1, "[perl #38612]"); # Still no core dump? We are fine.

