use strict;
package Test;
use Test::Harness 1.1601 ();
use Carp;
use vars qw($VERSION @ISA @EXPORT $ntest %todo %history $TestLevel);
$VERSION = '0.08';
require Exporter;
@ISA=('Exporter');
@EXPORT= qw(&plan &ok &skip $ntest);

$TestLevel = 0;		# how many extra stack frames to skip
$|=1;
#$^W=1;  ?
$ntest=1;

# Use of this variable is strongly discouraged.  It is set mainly to
# help test coverage analyzers know which test is running.
$ENV{REGRESSION_TEST} = $0;

sub plan {
    croak "Test::plan(%args): odd number of arguments" if @_ & 1;
    my $max=0;
    for (my $x=0; $x < @_; $x+=2) {
	my ($k,$v) = @_[$x,$x+1];
	if ($k =~ /^test(s)?$/) { $max = $v; }
	elsif ($k eq 'todo' or 
	       $k eq 'failok') { for (@$v) { $todo{$_}=1; }; }
	else { carp "Test::plan(): skipping unrecognized directive '$k'" }
    }
    my @todo = sort { $a <=> $b } keys %todo;
    if (@todo) {
	print "1..$max todo ".join(' ', @todo).";\n";
    } else {
	print "1..$max\n";
    }
}

sub to_value {
    my ($v) = @_;
    (ref $v or '') eq 'CODE' ? $v->() : $v;
}

# prototypes are not used for maximum flexibility

# STDERR is NOT used for diagnostic output that should be fixed before
# the module is released.

sub ok {
    my ($pkg,$file,$line) = caller($TestLevel);
    my $repetition = ++$history{"$file:$line"};
    my $context = ("$file at line $line".
		   ($repetition > 1 ? " (\#$repetition)" : ''));
    my $ok=0;

    if (@_ == 0) {
	print "not ok $ntest\n";
	print "# test $context: DOESN'T TEST ANYTHING!\n";
    } else {
	my $result = to_value(shift);
	my ($expected,$diag);
	if (@_ == 0) {
	    $ok = $result;
	} else {
	    $expected = to_value(shift);
	    $ok = $result eq $expected;
	}
	if ($todo{$ntest}) {
	    if ($ok) { 
		print "ok $ntest # Wow!\n";
	    } else {
		$diag = to_value(shift) if @_;
		if (!$diag) {
		    print "not ok $ntest # (failure expected)\n";
		} else {
		    print "not ok $ntest # (failure expected: $diag)\n";
		}
	    }
	} else {
	    print "not " if !$ok;
	    print "ok $ntest\n";

	    if (!$ok) {
		$diag = to_value(shift) if @_;
		if (!defined $expected) {
		    if (!$diag) {
			print STDERR "# Failed $context\n";
		    } else {
			print STDERR "# Failed $context: $diag\n";
		    }
		} else {
		    print STDERR "#      Got: '$result' ($context)\n";
		    if (!$diag) {
			print STDERR "# Expected: '$expected'\n";
		    } else {
			print STDERR "# Expected: '$expected' ($diag)\n";
		    }
		}
	    }
	}
    }
    ++ $ntest;
    $ok;
}

sub skip {
    if (to_value(shift)) {
	print "ok $ntest # skip\n";
	++ $ntest;
	1;
    } else {
	local($TestLevel) += 1;  #ignore this stack frame
	ok(@_);
    }
}

1;
__END__

=head1 NAME

  Test - provides a simple framework for writing test scripts

=head1 SYNOPSIS

  use strict;
  use Test;
  BEGIN { plan tests => 12, todo => [3,4] }

  ok(0); # failure
  ok(1); # success

  ok(0); # ok, expected failure (see todo list, above)
  ok(1); # surprise success!

  ok(0,1);             # failure: '0' ne '1'
  ok('broke','fixed'); # failure: 'broke' ne 'fixed'
  ok('fixed','fixed'); # success: 'fixed' eq 'fixed'

  ok(sub { 1+1 }, 2);  # success: '2' eq '2'
  ok(sub { 1+1 }, 3);  # failure: '2' ne '3'
  ok(0, int(rand(2));  # (just kidding! :-)

  my @list = (0,0);
  ok(scalar(@list), 3, "\@list=".join(',',@list));  #extra diagnostics

  skip($feature_is_missing, ...);    #do platform specific test

=head1 DESCRIPTION

Test::Harness expects to see particular output when it executes tests.
This module aims to make writing proper test scripts just a little bit
easier (and less error prone :-).

=head1 TEST TYPES

=over 4

=item * NORMAL TESTS

These tests are expected to succeed.  If they don't, something's
screwed up!

=item * SKIPPED TESTS

Skip tests need a platform specific feature that might or might not be
available.  The first argument should evaluate to true if the required
feature is NOT available.  After the first argument, skip tests work
exactly the same way as do normal tests.

=item * TODO TESTS

TODO tests are designed for maintaining an executable TODO list.
These tests are expected NOT to succeed (otherwise the feature they
test would be on the new feature list, not the TODO list).

Packages should NOT be released with successful TODO tests.  As soon
as a TODO test starts working, it should be promoted to a normal test
and the new feature should be documented in the release notes.

=back

=head1 SEE ALSO

L<Test::Harness> and various test coverage analysis tools.

=head1 AUTHOR

Copyright © 1998 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
