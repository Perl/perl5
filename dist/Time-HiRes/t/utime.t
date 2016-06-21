use strict;

BEGIN {
    require Time::HiRes;
    unless(&Time::HiRes::d_hires_utime) {
	require Test::More;
	Test::More::plan(skip_all => "no hires_utime()");
    }
}

use Test::More;
use t::Watchdog;
use File::Temp qw( tempfile );

use Config;

my $atime = 1.111111111;
my $mtime = 2.222222222;

subtest "utime \$fh" => sub {
	my ($fh, $filename) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	is Time::HiRes::utime($atime, $mtime, $fh), 1, "One file changed";
	my ($got_atime, $got_mtime) = ( Time::HiRes::stat($filename) )[8, 9];
	is $got_atime, $atime, "atime set correctly";
	is $got_mtime, $mtime, "mtime set correctly";
};

subtest "utime \$filename" => sub {
	my ($fh, $filename) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	is Time::HiRes::utime($atime, $mtime, $filename), 1, "One file changed";
	my ($got_atime, $got_mtime) = ( Time::HiRes::stat($fh) )[8, 9];
	is $got_atime, $atime, "atime set correctly";
	is $got_mtime, $mtime, "mtime set correctly";
};

subtest "utime \$filename and \$fh" => sub {
	my ($fh1, $filename1) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	my ($fh2, $filename2) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	is Time::HiRes::utime($atime, $mtime, $filename1, $fh2), 2, "Two files changed";
	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($fh1) )[8, 9];
		is $got_atime, $atime, "File 1 atime set correctly";
		is $got_mtime, $mtime, "File 1 mtime set correctly";
	}
	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($filename2) )[8, 9];
		is $got_atime, $atime, "File 2 atime set correctly";
		is $got_mtime, $mtime, "File 2 mtime set correctly";
	}
};

subtest "utime undef sets time to now" => sub {
	my ($fh1, $filename1) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );
	my ($fh2, $filename2) = tempfile( "Time-HiRes-utime-XXXXXXXXX", UNLINK => 1 );

	my $now = Time::HiRes::time;
	is Time::HiRes::utime(undef, undef, $filename1, $fh2), 2, "Two files changed";

	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($fh1) )[8, 9];
		cmp_ok abs( $got_atime - $now), '<', 0.1, "File 1 atime set correctly";
		cmp_ok abs( $got_mtime - $now), '<', 0.1, "File 1 mtime set correctly";
	}
	{
		my ($got_atime, $got_mtime) = ( Time::HiRes::stat($filename2) )[8, 9];
		cmp_ok abs( $got_atime - $now), '<', 0.1, "File 2 atime set correctly";
		cmp_ok abs( $got_mtime - $now), '<', 0.1, "File 2 mtime set correctly";
	}
};

subtest "negative atime dies" => sub {
	eval { Time::HiRes::utime(-4, $mtime) };
	like $@, qr/::utime\(-4, 2\.22222\): negative time not invented yet/,
		"negative time error";
};

subtest "negative mtime dies" => sub {
	eval { Time::HiRes::utime($atime, -4) };
	like $@, qr/::utime\(1.11111, -4\): negative time not invented yet/,
		"negative time error";
};

done_testing;
1;
