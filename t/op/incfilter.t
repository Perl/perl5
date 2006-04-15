#!./perl -w

# Tests for the source filters in coderef-in-@INC

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: not perlio\n";
	exit 0;
    }
    require "test.pl";
}
use strict;

plan(tests => 12);

unshift @INC, sub {
    no warnings 'uninitialized';
    ref $_[1] eq 'ARRAY' ? @{$_[1]} : $_[1];
};

my $fh;

open $fh, "<", \'pass("Can return file handles from \@INC");';
do $fh;

my @origlines = ("# This is a blank line\n",
		 "pass('Can return generators from \@INC');\n",
		 "pass('Which return multiple lines');\n",
		 "1",
		 );
my @lines = @origlines;
sub generator {
    $_ = shift @lines;
    # Return of 0 marks EOF
    return defined $_ ? 1 : 0;
};

do \&generator;

@lines = @origlines;
# Check that the array dereferencing works ready for the more complex tests:
do [\&generator];

do [sub {
	my $param = $_[1];
	is (ref $param, 'ARRAY', "Got our parameter");
	$_ = shift @$param;
	return defined $_ ? 1 : 0;
    }, ["pass('Can return generators which take state');\n",
	"pass('And return multiple lines');\n",
	]];
   

open $fh, "<", \'fail("File handles and filters work from \@INC");';

do [$fh, sub {s/fail/pass/}];

open $fh, "<", \'fail("File handles and filters with state work from \@INC");';

do [$fh, sub {s/$_[1]/pass/}, 'fail'];
