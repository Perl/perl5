#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

tie my $c => 'Tie::Monitor';

sub expected_tie_calls {
    my ($obj, $rexp, $wexp) = @_;
    local $::Level = $::Level + 1;
    my ($rgot, $wgot) = $obj->init();
    is ($rgot, $rexp);
    is ($wgot, $wexp);
}

# Use ok() instead of is(), cmp_ok() etc, to strictly control number of accesses
my($r, $s);
ok($r = $c + 0 == 0, 'the thing itself');
expected_tie_calls(tied $c, 1, 0);
ok($r = "$c" eq '0', 'the thing itself');
expected_tie_calls(tied $c, 1, 0);

ok($c . 'x' eq '0x', 'concat');
expected_tie_calls(tied $c, 1, 0);
ok('x' . $c eq 'x0', 'concat');
expected_tie_calls(tied $c, 1, 0);
$s = $c . $c;
ok($s eq '00', 'concat');
expected_tie_calls(tied $c, 2, 0);
$r = 'x';
$s = $c = $r . 'y';
ok($s eq 'xy', 'concat');
expected_tie_calls(tied $c, 1, 1);
$s = $c = $c . 'x';
ok($s eq '0x', 'concat');
expected_tie_calls(tied $c, 2, 1);
$s = $c = 'x' . $c;
ok($s eq 'x0', 'concat');
expected_tie_calls(tied $c, 2, 1);
$s = $c = $c . $c;
ok($s eq '00', 'concat');
expected_tie_calls(tied $c, 3, 1);

$s = chop($c);
ok($s eq '0', 'multiple magic in core functions');
expected_tie_calls(tied $c, 1, 1);

# was a glob
my $tied_to = tied $c;
$c = *strat;
$s = $c;
ok($s eq *strat,
   'Assignment should not ignore magic when the last thing assigned was a glob');
expected_tie_calls($tied_to, 1, 1);

# A plain *foo should not call get-magic on *foo.
# This method of scalar-tying an immutable glob relies on details of the
# current implementation that are subject to change. This test may need to
# be rewritten if they do change.
my $tyre = tie $::{gelp} => 'Tie::Monitor';
# Compilation of this eval autovivifies the *gelp glob.
eval '$tyre->init(0); () = \*gelp';
my($rgot, $wgot) = $tyre->init(0);
ok($rgot == 0, 'a plain *foo causes no get-magic');
ok($wgot == 0, 'a plain *foo causes no set-magic');

done_testing();

# adapted from Tie::Counter by Abigail
package Tie::Monitor;

sub TIESCALAR {
    my($class, $value) = @_;
    bless {
	read => 0,
	write => 0,
	values => [ 0 ],
    };
}

sub FETCH {
    my $self = shift;
    ++$self->{read};
    $self->{values}[$#{ $self->{values} }];
}

sub STORE {
    my($self, $value) = @_;
    ++$self->{write};
    push @{ $self->{values} }, $value;
}

sub init {
    my $self = shift;
    my @results = ($self->{read}, $self->{write});
    $self->{read} = $self->{write} = 0;
    $self->{values} = [ 0 ];
    @results;
}
