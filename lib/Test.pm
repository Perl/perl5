use strict;
package Test;
use Test::Harness 1.1601 ();
use Carp;
use vars qw($VERSION @ISA @EXPORT $ntest %todo);
$VERSION = '0.06';
require Exporter;
@ISA=('Exporter');
@EXPORT= qw(&plan &ok &skip $ntest);

$|=1;
#$^W=1;  ?
$ntest=1;

# Use of this variable is strongly discouraged.  It is set
# exclusively for test coverage analyzers.
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

sub ok {
    my ($ok, $guess) = @_;
    carp "(this is ok $ntest)" if defined $guess && $guess != $ntest;
    $ok = $ok->() if (ref $ok or '') eq 'CODE';
    if ($ok) {
	if ($todo{$ntest}) {
	    print("ok $ntest # Wow!\n");
	} else {
	    print("ok $ntest # (failure expected)\n");
	}
    } else {
	print("not ok $ntest\n");
    }
    ++ $ntest;
    $ok;
}

sub skip {
    my ($toskip, $ok, $guess) = @_;
    carp "(this is skip $ntest)" if defined $guess && $guess != $ntest;
    $toskip = $toskip->() if (ref $toskip or '') eq 'CODE';
    if ($toskip) {
	print "ok $ntest # skip\n";
	++ $ntest;
	1;
    } else {
	ok($ok);
    }
}

1;
__END__

=head1 NAME

  Test - provides a simple framework for writing test scripts

=head1 SYNOPSIS

  use strict;
  use Test;
  BEGIN { plan tests => 5, todo => [3,4] }

  ok(0); #failure
  ok(1); #success

  ok(0); #ok, expected failure (see todo above)
  ok(1); #surprise success!

  skip($feature_is_missing, sub {...});    #do platform specific test

=head1 DESCRIPTION

Test::Harness expects to see particular output when it executes test
scripts.  This module tries to make conforming just a little bit
easier (and less error prone).

=head1 TEST CATEGORIES

=over 4

=item * NORMAL TESTS

These tests are expected to succeed.  If they don't, something is
wrong!

=item * SKIPPED TESTS

C<skip> should be used to skip tests for which a platform specific
feature isn't available.

=item * TODO TESTS

TODO tests are designed for the purpose of maintaining an executable
TODO list.  These tests are expected NOT to succeed (otherwise the
feature they test would be on the new feature list, not the TODO
list).

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
