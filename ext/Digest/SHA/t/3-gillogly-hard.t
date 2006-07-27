# Test against long bitwise vectors from Jim Gillogly and Francois Grieu
#
# http://www.chiark.greenend.org.uk/pipermail/ukcrypto/1999-February/003538.html

use Test;
use strict;
use integer;
use File::Basename qw(dirname);
use File::Spec;
use Digest::SHA;

BEGIN {
	if ($ENV{PERL_CORE}) {
		chdir 't' if -d 't';
		@INC = '../lib';
	}
}

#	SHA-1 Test Vectors
#
#	In the following we use the notation bitstring#n to mean a bitstring
#	repeated n (in decimal) times, and we use | for concatenation.
#	Therefore 110#3|1 is 1101101101.
#
#	Here is a set near 2^32 bits to test the roll-over in the length
#	field from one to two 32-bit words:
#
#	110#1431655764|11 1eef5a18 969255a3 b1793a2a 955c7ec2 8cd221a5
#	110#1431655765|   7a1045b9 14672afa ce8d90e6 d19b3a6a da3cb879
#	110#1431655765|1  d5e09777 a94f1ea9 240874c4 8d9fecb6 b634256b
#	110#1431655765|11 eb256904 3c3014e5 1b2862ae 6eb5fb4e 0b851d99
#
#	011#1431655764|01 4CB0C4EF 69143D5B F34FC35F 1D4B19F6 ECCAE0F2
#	011#1431655765    47D92F91 1FC7BB74 DE00ADFC 4E981A81 05556D52
#	011#1431655765|0  A3D7438C 589B0B93 2AA91CC2 446F06DF 9ABC73F0
#	011#1431655765|01 3EEE3E1E 28DEDE2C A444D68D A5675B2F AAAB3203

my(@vec110, @vec011);

BEGIN {
	@vec110 = (	# 110 rep 1431655764
		"11", "1eef5a18969255a3b1793a2a955c7ec28cd221a5",
		"110", "7a1045b914672aface8d90e6d19b3a6ada3cb879",
		"1101", "d5e09777a94f1ea9240874c48d9fecb6b634256b",
		"11011", "eb2569043c3014e51b2862ae6eb5fb4e0b851d99"
	);

	@vec011 = (	# 011 rep 1431655764
		"01", "4cb0c4ef69143d5bf34fc35f1d4b19f6eccae0f2",
		"011", "47d92f911fc7bb74de00adfc4e981a8105556d52",
		"0110", "a3d7438c589b0b932aa91cc2446f06df9abc73f0",
		"01101", "3eee3e1e28dede2ca444d68da5675b2faaab3203"
	);
	plan tests => scalar(@vec110) / 2 + scalar(@vec011) / 2;
}

my $STATE110 = File::Spec->catfile(dirname($0), "gillogly", "state.110");
my $STATE011 = File::Spec->catfile(dirname($0), "gillogly", "state.011");

my $reps = 1 << 14;
my $loops = int(1431655764 / $reps);
my $rest = 3 * (1431655764 - $loops * $reps);

sub state110 {
	my $state;
	my $bitstr;

	$state = Digest::SHA->new(1);
	if (-r $STATE110) {
		if ($state->load($STATE110)) {
			return($state);
		}
	}
	$bitstr = pack("B*", "110" x $reps);
	$state->reset;
	for (my $i = 0; $i < $loops; $i++) {
		$state->add_bits($bitstr, 3 * $reps);
	}
	$state->add_bits($bitstr, $rest);
	$state->dump($STATE110);
	return($state);
}

sub state011 {
	my $state;
	my $bitstr;

	$state = Digest::SHA->new(1);
	if (-r $STATE011) {
		if ($state->load($STATE011)) {
			return($state);
		}
	}
	$bitstr = pack("B*", "011" x $reps);
	$state->reset;
	for (my $i = 0; $i < $loops; $i++) {
		$state->add_bits($bitstr, 3 * $reps);
	}
	$state->add_bits($bitstr, $rest);
	$state->dump($STATE011);
	return($state);
}

my $i;

my $state110 = state110();
for ($i = 0; $i < @vec110/2; $i++) {
	my $state = $state110->clone;
	$state->add_bits($vec110[2*$i]);
	ok($state->hexdigest, $vec110[2*$i+1]);
}

my $state011 = state011();
for ($i = 0; $i < @vec011/2; $i++) {
	my $state = $state011->clone;
	$state->add_bits($vec011[2*$i]);
	ok($state->hexdigest, $vec011[2*$i+1]);
}
