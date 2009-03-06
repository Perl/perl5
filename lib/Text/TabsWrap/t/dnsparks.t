#!/usr/bin/perl -I. -w

BEGIN {
	if ($ENV{HARNESS_ACTIVE}) {
		print "1..0 # Skipped: not a standard regression test\n";
		exit;
	}
	unless (eval { require Benchmark; }) {
		print "1..0 # Skipped: this test requires Benchmark.pm\n";
		exit;
	}
}

#From:     dnsparks@juno.com
#Subject:  Text::Wrap suggestions
#To:       muir@idiom.com
#Date:     Sat, 10 Feb 2001 21:50:29 -0500
#
#David,
#
#I had a "word wrapping" problem to solve at work the other week.
#Text::Wrap would have done exactly what I needed, but at work we use
#Smalltalk. :-) (I ended up thinking about it at home, where I don't have
#Smalltalk, so I first coded it in Perl and then "translated" my solution
#at work.)
#
#I must admit that I was dealing with a specialized case; I didn't want to
#prepend any strings on the first or subsequent lines of the paragraph
#begin created. In other words, had we been using Perl at work, I would
#have done something like this:
#
#   use Text::Wrap qw(wrap $columns);
#   # ... set $columns, $string, etc. ...
#   return wrap("", "", $string);
#
#By the way, the copy of Wrap.pm came with the IndigoPerl distribution I
#recently downloaded. This is the version string: $VERSION = 98.112902; I
#don't know if that's the most recent.
#
#When I had some time, I was curious to see how my solution compared to
#using your module. So, I threw together the following script:
#
#The interesting thing, which really surprised me, was that the results
#seemed to indicate that my version ran faster. I was surprised because
#I'm used to thinking that the standard Perl modules would always present
#a better solution than "reinventing the wheel".
#
#  mine: 24 wallclock secs (18.49 usr +  0.00 sys = 18.49 CPU) @ 54.09/s
#(n=1000)
#  module: 58 wallclock secs (56.44 usr +  0.02 sys = 56.46 CPU) @ 17.71/s
#(n=1000)
#
#Then, it occurred to me that the diffrence may be attributable to my
#using substr() vs. the module relying on s///. (I recall reading
#something on perlmonks.org a while back that indicated that substr() is
#often faster than s///.)
#
#I realize that my solution has its problems (doesn't include ability to
#specify first/subsequent line prefixes, and the possibility that it may
#recurse itself out of memory, given a big enough input string). But I
#though you might be interested in my findings.
#
#Dan
#(perlmonks.org nick: t'mo)


use strict;
use Text::Wrap qw(wrap $columns);
use Benchmark;

my $testString = 'a;kjdf;ldsjf afkjad;fkjafkjafkj; dsfljasdfkjasfj;dThis
is a test. It is only a test. Do not be alarmed, as the test should only
take several seconds to run. Yadda yadda yadda...a;kjdf;ldsjf
afkjad;fkjafkjafkj; dsfljasdfkjasfj;dThis is a test. It is only a test.
Do not be alarmed, as the test should only take several seconds to run.
Yadda yadda yadda...a;kjdf;ldsjf afkjad;fkjafkjafkj;
dsfljasdfkjasfj;dThis is a test. It is only a test. Do not be alarmed, as
the test should only take several seconds to run. Yadda yadda
yadda...a;kjdf;ldsjf afkjad;fkjafkjafkj; dsfljasdfkjasfj;dThis is a test.
It is only a test. Do not be alarmed, as the test should only take
several seconds to run. Yadda yadda yadda...' x 5;

$columns = 55;

sub prefix {
	my $length = shift;
	my $string = shift;

	return "" if( ! $string );

	return prefix($length, substr($string, 1))
		if( $string =~ /^\s/ );

	if( length $string <= $length ) {
		chop($string) while( $string =~ /\s$/ );
		return $string . "\n";
	}

	my $pre = substr($string, 0, $length);
	my $post = substr($string, $length);

	if( $pre =~ /\s$/ ) {
		chop($pre) while( $pre =~ /\s$/ );
		return $pre . "\n" . prefix($length, $post);
	}
	else {
		if( $post =~ /^\s/ ) {
			return $pre . "\n" . prefix($length, $post);
		}
		else {
			if( $pre !~ /\s/ ) {
				return $pre . "\n" . prefix($length, $post);
			}
			else {
				$pre =~ /(.*)\s+([^\s]*)/;
				$post = $2 . $post;
				return $1 . "\n" . prefix($length, $post);
			}
		}
	}
}

my $x = prefix($columns, $testString);
my $y = wrap("", "", $testString);

unless ($x ne $y) {
	print "1..0 # Skipped: dnspark's module doesn't give the same answer\n";
	exit;
}

my $cnt = -T STDOUT ? 200 : 40;
my $results = timethese($cnt, {
	mine => sub { my $res = prefix($columns, $testString) },
	module => sub { my $res = wrap("", "", $testString) },
});

if ($results->{module}[1] < $results->{mine}[1]) {
	print "1..1\nok 1\n";
} else {
	print "1..0 # Skipped: Dan's implmentation is faster\n";
}


