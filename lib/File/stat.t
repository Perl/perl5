#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More;

BEGIN {
    our $hasst;
    eval { my @n = stat "TEST" };
    $hasst = 1 unless $@ && $@ =~ /unimplemented/;
    unless ($hasst) { plan skip_all => "no stat"; exit 0 }
    use Config;
    $hasst = 0 unless $Config{'i_sysstat'} eq 'define';
    unless ($hasst) { plan skip_all => "no sys/stat.h"; exit 0 }
    our @stat = stat "TEST"; # This is the function stat.
    unless (@stat) { print "1..0 # Skip: no file TEST\n"; exit 0 }
}

plan tests => 16;

use_ok( 'File::stat' );

my $stat = File::stat::stat( "TEST" ); # This is the OO stat.
ok( ref($stat), 'should build a stat object' );

is( $stat->dev, $stat[0], "device number in position 0" );

# On OS/2 (fake) ino is not constant, it is incremented each time
SKIP: {
	skip(1, 'inode number is not constant on OS/2') if $^O eq 'os2';
	is( $stat->ino, $stat[1], "inode number in position 1" );
}

is( $stat->mode, $stat[2], "file mode in position 2" );

is( $stat->nlink, $stat[3], "number of links in position 3" );

is( $stat->uid, $stat[4], "owner uid in position 4" );

is( $stat->gid, $stat[5], "group id in position 5" );

is( $stat->rdev, $stat[6], "device identifier in position 6" );

is( $stat->size, $stat[7], "file size in position 7" );

is( $stat->atime, $stat[8], "last access time in position 8" );

is( $stat->mtime, $stat[9], "last modify time in position 9" );

is( $stat->ctime, $stat[10], "change time in position 10" );

is( $stat->blksize, $stat[11], "IO block size in position 11" );

is( $stat->blocks, $stat[12], "number of blocks in position 12" );

local $!;
$stat = stat '/notafile';
like( $!, qr/^No such file/, 
	"should leave 'No such file' error in \$! with invalid file" );

# Testing pretty much anything else is unportable.
