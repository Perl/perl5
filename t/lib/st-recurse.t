#!./perl

# $Id: recurse.t,v 1.0 2000/09/01 19:40:42 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the same terms as Perl 5, as specified
#  in the README file that comes with the distribution.
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

print "1..23\n";

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
	my $t = dclone($self->{sync});
	return ("", [$t, $self->{ext}], $self, $self->{ext});
}

sub STORABLE_thaw {
	my $self = shift;
	my ($cloning, $undef, $a, $obj, $ext) = @_;
	die "STORABLE_thaw #1" unless $obj eq $self;
	die "STORABLE_thaw #2" unless ref $a eq 'ARRAY';
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
