#!./perl

# $Id: recurse.t,v 1.0.1.3 2001/02/17 12:28:33 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the same terms as Perl 5, as specified
#  in the README file that comes with the distribution.
#  
# $Log: recurse.t,v $
# Revision 1.0.1.3  2001/02/17 12:28:33  ram
# patch8: ensure blessing occurs ASAP, specially designed for hooks
#
# Revision 1.0.1.2  2000/11/05 17:22:05  ram
# patch6: stress hook a little more with refs to lexicals
#
# $Log: recurse.t,v $
# Revision 1.0.1.1  2000/09/17 16:48:05  ram
# patch1: added test case for store hook bug
#
# $Log: recurse.t,v $
# Revision 1.0  2000/09/01 19:40:42  ram
# Baseline for first official release.
#

sub BEGIN {
    chdir('t') if -d 't';
    @INC = '.'; 
    push @INC, '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bStorable\b/) {
        print "1..0 # Skip: Storable was not built\n";
        exit 0;
    }
    require 'lib/st-dump.pl';
}

sub ok;

use Storable qw(freeze thaw dclone);

print "1..32\n";

package OBJ_REAL;

use Storable qw(freeze thaw);

@x = ('a', 1);

sub make { bless [], shift }

sub STORABLE_freeze {
	my $self = shift;
	my $cloning = shift;
	die "STORABLE_freeze" unless Storable::is_storing;
	return (freeze(\@x), $self);
}

sub STORABLE_thaw {
	my $self = shift;
	my $cloning = shift;
	my ($x, $obj) = @_;
	die "STORABLE_thaw #1" unless $obj eq $self;
	my $len = length $x;
	my $a = thaw $x;
	die "STORABLE_thaw #2" unless ref $a eq 'ARRAY';
	die "STORABLE_thaw #3" unless @$a == 2 && $a->[0] eq 'a' && $a->[1] == 1;
	@$self = @$a;
	die "STORABLE_thaw #4" unless Storable::is_retrieving;
}

package OBJ_SYNC;

@x = ('a', 1);

sub make { bless {}, shift }

sub STORABLE_freeze {
	my $self = shift;
	my ($cloning) = @_;
	return if $cloning;
	return ("", \@x, $self);
}

sub STORABLE_thaw {
	my $self = shift;
	my ($cloning, $undef, $a, $obj) = @_;
	die "STORABLE_thaw #1" unless $obj eq $self;
	die "STORABLE_thaw #2" unless ref $a eq 'ARRAY' || @$a != 2;
	$self->{ok} = $self;
}

package OBJ_SYNC2;

use Storable qw(dclone);

sub make {
	my $self = bless {}, shift;
	my ($ext) = @_;
	$self->{sync} = OBJ_SYNC->make;
	$self->{ext} = $ext;
	return $self;
}

sub STORABLE_freeze {
	my $self = shift;
	my %copy = %$self;
	my $r = \%copy;
	my $t = dclone($r->{sync});
	return ("", [$t, $self->{ext}], $r, $self, $r->{ext});
}

sub STORABLE_thaw {
	my $self = shift;
	my ($cloning, $undef, $a, $r, $obj, $ext) = @_;
	die "STORABLE_thaw #1" unless $obj eq $self;
	die "STORABLE_thaw #2" unless ref $a eq 'ARRAY';
	die "STORABLE_thaw #3" unless ref $r eq 'HASH';
	die "STORABLE_thaw #4" unless $a->[1] == $r->{ext};
	$self->{ok} = $self;
	($self->{sync}, $self->{ext}) = @$a;
}

package OBJ_REAL2;

use Storable qw(freeze thaw);

$MAX = 20;
$recursed = 0;
$hook_called = 0;

sub make { bless [], shift }

sub STORABLE_freeze {
	my $self = shift;
	$hook_called++;
	return (freeze($self), $self) if ++$recursed < $MAX;
	return ("no", $self);
}

sub STORABLE_thaw {
	my $self = shift;
	my $cloning = shift;
	my ($x, $obj) = @_;
	die "STORABLE_thaw #1" unless $obj eq $self;
	$self->[0] = thaw($x) if $x ne "no";
	$recursed--;
}

package main;

my $real = OBJ_REAL->make;
my $x = freeze $real;
ok 1, 1;

my $y = thaw $x;
ok 2, 1;
ok 3, $y->[0] eq 'a';
ok 4, $y->[1] == 1;

my $sync = OBJ_SYNC->make;
$x = freeze $sync;
ok 5, 1;

$y = thaw $x;
ok 6, 1;
ok 7, $y->{ok} == $y;

my $ext = [1, 2];
$sync = OBJ_SYNC2->make($ext);
$x = freeze [$sync, $ext];
ok 8, 1;

my $z = thaw $x;
$y = $z->[0];
ok 9, 1;
ok 10, $y->{ok} == $y;
ok 11, ref $y->{sync} eq 'OBJ_SYNC';
ok 12, $y->{ext} == $z->[1];

$real = OBJ_REAL2->make;
$x = freeze $real;
ok 13, 1;
ok 14, $OBJ_REAL2::recursed == $OBJ_REAL2::MAX;
ok 15, $OBJ_REAL2::hook_called == $OBJ_REAL2::MAX;

$y = thaw $x;
ok 16, 1;
ok 17, $OBJ_REAL2::recursed == 0;

$x = dclone $real;
ok 18, 1;
ok 19, ref $x eq 'OBJ_REAL2';
ok 20, $OBJ_REAL2::recursed == 0;
ok 21, $OBJ_REAL2::hook_called == 2 * $OBJ_REAL2::MAX;

ok 22, !Storable::is_storing;
ok 23, !Storable::is_retrieving;

#
# The following was a test-case that Salvador Ortiz Garcia <sog@msg.com.mx>
# sent me, along with a proposed fix.
#

package Foo;

sub new {
	my $class = shift;
	my $dat = shift;
	return bless {dat => $dat}, $class;
}

package Bar;
sub new {
	my $class = shift;
	return bless {
		a => 'dummy',
		b => [ 
			Foo->new(1),
			Foo->new(2), # Second instance of a Foo 
		]
	}, $class;
}

sub STORABLE_freeze {
	my($self,$clonning) = @_;
	return "$self->{a}", $self->{b};
}

sub STORABLE_thaw {
	my($self,$clonning,$dummy,$o) = @_;
	$self->{a} = $dummy;
	$self->{b} = $o;
}

package main;

my $bar = new Bar;
my $bar2 = thaw freeze $bar;

ok 24, ref($bar2) eq 'Bar';
ok 25, ref($bar->{b}[0]) eq 'Foo';
ok 26, ref($bar->{b}[1]) eq 'Foo';
ok 27, ref($bar2->{b}[0]) eq 'Foo';
ok 28, ref($bar2->{b}[1]) eq 'Foo';

#
# The following attempts to make sure blessed objects are blessed ASAP
# at retrieve time.
#

package CLASS_1;

sub make {
	my $self = bless {}, shift;
	return $self;
}

package CLASS_2;

sub make {
	my $self = bless {}, shift;
	my ($o) = @_;
	$self->{c1} = CLASS_1->make();
	$self->{o} = $o;
	$self->{c3} = bless CLASS_1->make(), "CLASS_3";
	$o->set_c2($self);
	return $self;
}

sub STORABLE_freeze {
	my($self, $clonning) = @_;
	return "", $self->{c1}, $self->{c3}, $self->{o};
}

sub STORABLE_thaw {
	my($self, $clonning, $frozen, $c1, $c3, $o) = @_;
	main::ok 29, ref $self eq "CLASS_2";
	main::ok 30, ref $c1 eq "CLASS_1";
	main::ok 31, ref $c3 eq "CLASS_3";
	main::ok 32, ref $o eq "CLASS_OTHER";
	$self->{c1} = $c1;
	$self->{c3} = $c3;
}

package CLASS_OTHER;

sub make {
	my $self = bless {}, shift;
	return $self;
}

sub set_c2 { $_[0]->{c2} = $_[1] }

package main;

my $o = CLASS_OTHER->make();
my $c2 = CLASS_2->make($o);
my $so = thaw freeze $o;

