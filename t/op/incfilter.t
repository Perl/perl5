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
use Filter::Util::Call;

plan(tests => 19);

unshift @INC, sub {
    no warnings 'uninitialized';
    ref $_[1] eq 'ARRAY' ? @{$_[1]} : $_[1];
};

my $fh;

open $fh, "<", \'pass("Can return file handles from \@INC");';
do $fh or die;

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

do \&generator or die;

@lines = @origlines;
# Check that the array dereferencing works ready for the more complex tests:
do [\&generator] or die;

do [sub {
	my $param = $_[1];
	is (ref $param, 'ARRAY', "Got our parameter");
	$_ = shift @$param;
	return defined $_ ? 1 : 0;
    }, ["pass('Can return generators which take state');\n",
	"pass('And return multiple lines');\n",
	]] or die;
   

open $fh, "<", \'fail("File handles and filters work from \@INC");';

do [$fh, sub {s/fail/pass/}] or die;

open $fh, "<", \'fail("File handles and filters with state work from \@INC");';

do [$fh, sub {s/$_[1]/pass/}, 'fail'] or die;

print "# 2 tests with pipes from subprocesses.\n";

open $fh, 'echo pass|' or die $!;

do $fh or die;

open $fh, 'echo fail|' or die $!;

do [$fh, sub {s/$_[1]/pass/}, 'fail'] or die;

sub rot13_filter {
    filter_add(sub {
		   my $status = filter_read();
		   tr/A-Za-z/N-ZA-Mn-za-m/;
		   $status;
	       })
}

open $fh, "<", \<<'EOC';
BEGIN {rot13_filter};
cnff("This will rot13'ed prepend");
EOC

do $fh or die;

open $fh, "<", \<<'EOC';
ORTVA {ebg13_svygre};
pass("This will rot13'ed twice");
EOC

do [$fh, sub {tr/A-Za-z/N-ZA-Mn-za-m/;}] or die;

my $count = 32;
sub prepend_rot13_filter {
    filter_add(sub {
		   my $previous = defined $_ ? $_ : '';
		   # Filters should append to any existing data in $_
		   # But (logically) shouldn't filter it twice.
		   my $test = "fzrt!";
		   $_ = $test;
		   my $status = filter_read();
		   # Sadly, doing this inside the source filter causes an
		   # infinte loop
		   my $got = substr $_, 0, length $test, '';
		   is $got, $test, "Upstream didn't alter existing data";
		   tr/A-Za-z/N-ZA-Mn-za-m/;
		   $_ = $previous . $_;
		   die "Looping infinitely" unless $count--;
		   $status;
	       })
}

open $fh, "<", \<<'EOC';
ORTVA {cercraq_ebg13_svygre};
pass("This will rot13'ed twice");
EOC

do [$fh, sub {tr/A-Za-z/N-ZA-Mn-za-m/;}] or die;
