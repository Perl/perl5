#!./perl

use strict;
use warnings;

# for _is_type() tests
use Config;

# for new() tests
use Cwd;
use File::Path;

# for directories() tests
use File::Basename;

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

use Test::More tests => 43;

use_ok( 'ExtUtils::Installed' );

# saves having to qualify package name for class methods
my $ei = bless( {}, 'ExtUtils::Installed' );

# _is_prefix
is( $ei->_is_prefix('foo/bar', 'foo'), 1, 
	'_is_prefix() should match valid path prefix' );
is( $ei->_is_prefix('\foo\bar', '\bar'), 0, 
	'... should not match wrong prefix' );

# _is_type
is( $ei->_is_type(0, 'all'), 1, '_is_type() should be true for type of "all"' );

foreach my $path (qw( installman1dir installman3dir )) {
	my $file = $Config{$path} . '/foo';
	is( $ei->_is_type($file, 'doc'), 1, "... should find doc file in $path" );
	is( $ei->_is_type($file, 'prog'), 0, "... but not prog file in $path" );
}

is( $ei->_is_type($Config{prefix} . '/bar', 'prog'), 1, 
	"... should find prog file under $Config{prefix}" );
is( $ei->_is_type('bar', 'doc'), 0, 
	'... should not find doc file outside path' );
is( $ei->_is_type('bar', 'prog'), 0, 
	'... nor prog file outside path' );
is( $ei->_is_type('whocares', 'someother'), 0, '... nor other type anywhere' );

# _is_under
ok( $ei->_is_under('foo'), '_is_under() should return true with no dirs' );

my @under = qw( boo bar baz );
is( $ei->_is_under('foo', @under), 0, '... should find no file not under dirs');
is( $ei->_is_under('baz', @under), 1, '... should find file under dir' );

# new
my $realei = ExtUtils::Installed->new();

isa_ok( $realei, 'ExtUtils::Installed' );
isa_ok( $realei->{Perl}{packlist}, 'ExtUtils::Packlist' );
is( $realei->{Perl}{version}, $Config{version}, 
	'new() should set Perl version from %Config' );

my $wrotelist;
if (mkpath('auto/FakeMod')) {
	if (open(PACKLIST, '>', 'auto/FakeMod/.packlist')) {
		print PACKLIST 'list';
		close PACKLIST;
		if (open(FAKEMOD, '>', 'auto/FakeMod/FakeMod.pm')) {
			print FAKEMOD <<'FAKE';
package FakeMod;
use vars qw( $VERSION );
$VERSION = '1.1.1';
1;
FAKE

			close FAKEMOD;
			$wrotelist = 1;
		}
	}
}


SKIP: {
	skip( "could not write packlist: $!", 3 ) unless $wrotelist;

	# avoid warning and death by localizing glob
	local *ExtUtils::Installed::Config;
    my $fake_mod_dir = File::Spec->catdir(cwd(), 'auto', 'FakeMod');
	%ExtUtils::Installed::Config = (
		archlib		   => cwd(),
        installarchlib => cwd(),
		sitearch	   => $fake_mod_dir,
	);

	# necessary to fool new()
	push @INC, $fake_mod_dir;

	my $realei = ExtUtils::Installed->new();
	ok( exists $realei->{FakeMod}, 'new() should find modules with .packlists');
	isa_ok( $realei->{FakeMod}{packlist}, 'ExtUtils::Packlist' );
	is( $realei->{FakeMod}{version}, '1.1.1', 
		'... should find version in modules' );
}

# modules
$ei->{$_} = 1 for qw( abc def ghi );
is( join(' ', $ei->modules()), 'abc def ghi', 
	'modules() should return sorted keys' );

# files
$ei->{goodmod} = { 
	packlist => { 
		File::Spec->catdir($Config{installman1dir}, 'foo') => 1,
		File::Spec->catdir($Config{installman3dir}, 'bar') => 1,
		File::Spec->catdir($Config{prefix}, 'foobar') => 1,
		foobaz	=> 1,
	},
};

eval { $ei->files('badmod') };
like( $@, qr/badmod is not installed/,'files() should croak given bad modname');
eval { $ei->files('goodmod', 'badtype' ) };
like( $@, qr/type must be/,'files() should croak given bad type' );
my @files = $ei->files('goodmod', 'doc', $Config{installman1dir});
is( scalar @files, 1, '... should find doc file under given dir' );
like( $files[0], qr/foo$/, '... checking file name' );
@files = $ei->files('goodmod', 'doc');
is( scalar @files, 2, '... should find all doc files with no dir' );
@files = $ei->files('goodmod', 'prog', 'fake', 'fake2');
is( scalar @files, 0, '... should find no doc files given wrong dirs' );
@files = $ei->files('goodmod', 'prog');
is( scalar @files, 1, '... should find doc file in correct dir' );
like( $files[0], qr/foobar$/, '... checking file name' );
@files = $ei->files('goodmod');
is( scalar @files, 4, '... should find all files with no type specified' );
my %dirnames = map { $_ => dirname($_) } @files;

# directories
my @dirs = $ei->directories('goodmod', 'prog', 'fake');
is( scalar @dirs, 0, 'directories() should return no dirs if no files found' );
@dirs = $ei->directories('goodmod', 'doc');
is( scalar @dirs, 2, '... should find all files files() would' );
@dirs = $ei->directories('goodmod');
is( scalar @dirs, 4, '... should find all files files() would, again' );
@files = sort map { exists $dirnames{$_} ? $dirnames{$_} : '' } @files;
is( join(' ', @files), join(' ', @dirs), '... should sort output' );

# directory_tree
my $expectdirs = 
	dirname($Config{installman1dir}) eq dirname($Config{installman3dir}) ? 3 :2;

@dirs = $ei->directory_tree('goodmod', 'doc', dirname($Config{installman1dir}));
is( scalar @dirs, $expectdirs, 
	'directory_tree() should report intermediate dirs to those requested' );

my $fakepak = Fakepak->new(102);

$ei->{yesmod} = { 
	version		=> 101,
	packlist	=> $fakepak,
};

# these should all croak
foreach my $sub (qw( validate packlist version )) {
	eval { $ei->$sub('nomod') };
	like( $@, qr/nomod is not installed/, 
		"$sub() should croak when asked about uninstalled module" );
}

# validate
is( $ei->validate('yesmod'), 'validated', 
	'validate() should return results of packlist validate() call' );

# packlist
is( ${ $ei->packlist('yesmod') }, 102, 
	'packlist() should report installed mod packlist' );

# version
is( $ei->version('yesmod'), 101, 
	'version() should report installed mod version' );

# needs a DESTROY, for some reason
can_ok( $ei, 'DESTROY' );

END {
	if ($wrotelist) {
		for my $file (qw( .packlist FakePak.pm )) {
			1 while unlink $file;
		}
		File::Path::rmtree('auto') or warn "Couldn't rmtree auto: $!";
	}
}

package Fakepak;

sub new {
	my $class = shift;
	bless(\(my $scalar = shift), $class);
}

sub validate {
	'validated'
}
