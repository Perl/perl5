#!./perl -w

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
	1 while unlink 'ecmdfile';
	# forcibly remove ecmddir/temp2, but don't import mkpath
	use File::Path ();
	File::Path::rmtree( 'ecmddir' );
}

use Test::More tests => 21;
use File::Spec;

SKIP: {
	skip( 'ExtUtils::Command is a Win32 module', 21 )
	    unless $^O =~ /Win32/;

	use vars qw( *CORE::GLOBAL::exit );

	# bad neighbor, but test_f() uses exit()
	*CORE::GLOBAL::exit = sub { return @_ };

	use_ok( 'ExtUtils::Command' );

	# get a file in the current directory, replace last char with wildcard 
	my $file;
	{
		local *DIR;
		opendir(DIR, File::Spec->curdir());
		while ($file = readdir(DIR)) {
			last if $file =~ /^\w/;
		}
	}

	# this should find the file
	($ARGV[0] = $file) =~ s/.\z/\?/;
	ExtUtils::Command::expand_wildcards();

	is( scalar @ARGV, 1, 'found one file' );
	like( $ARGV[0], qr/$file/, 'expanded wildcard ? successfully' );

	# try it with the asterisk now
	($ARGV[0] = $file) =~ s/.{3}\z/\*/;
	ExtUtils::Command::expand_wildcards();

	ok( (grep { qr/$file/ } @ARGV), 'expanded wildcard * successfully' );

	# concatenate this file with itself
	# be extra careful the regex doesn't match itself
	my $out = tie *STDOUT, 'TieOut';
	@ARGV = ($0, $0);

	cat();
	is( scalar( $$out =~ s/use_ok\( 'ExtUtils::Command'//g), 2, 
		'concatenation worked' );

	# the truth value here is reversed -- Perl true is C false
	@ARGV = ( 'ecmdfile' );
	ok( test_f(), 'testing non-existent file' );

	@ARGV = ( 'ecmdfile' );
	is( ! test_f(), (-f 'ecmdfile'), 'testing non-existent file' );

	# these are destructive, have to keep setting @ARGV
	@ARGV = ( 'ecmdfile' );
        my $now = time;
	touch();

	@ARGV = ( 'ecmdfile' );
	ok( test_f(), 'now creating that file' );

	@ARGV = ( 'ecmdfile' );
	ok( -e $ARGV[0], 'created!' );

	# Just checking modify time stamp, access time stamp is set
	# to the beginning of the day in Win95
	is( (stat($ARGV[0]))[9], $now, 'checking modify time stamp' );

	# change a file to read-only
	@ARGV = ( 0600, 'ecmdfile' );
	ExtUtils::Command::chmod();

	is( (stat('ecmdfile'))[2] & 07777, 0600, 'removed non-owner permissions' );

	# mkpath
	@ARGV = ( File::Spec->join( 'ecmddir', 'temp2' ) );
	ok( ! -e $ARGV[0], 'temp directory not there yet' );

	mkpath();
	ok( -e $ARGV[0], 'temp directory created' );

	# copy a file to a nested subdirectory
	unshift @ARGV, 'ecmdfile';
	cp();

	ok( -e File::Spec->join( 'ecmddir', 'temp2', 'ecmdfile' ), 'copied okay' );

	# cp should croak if destination isn't directory (not a great warning)
	@ARGV = ( 'ecmdfile' ) x 3;
	eval { cp() };

	like( $@, qr/Too many arguments/, 'cp croaks on error' );

	# move a file to a subdirectory
	@ARGV = ( 'ecmdfile', 'ecmddir' );
	mv();

	ok( ! -e 'ecmdfile', 'moved file away' );
	ok( -e File::Spec->join( 'ecmddir', 'ecmdfile' ), 'file in new location' );

	# mv should also croak with the same wacky warning
	@ARGV = ( 'ecmdfile' ) x 3;

	eval { mv() };
	like( $@, qr/Too many arguments/, 'mv croaks on error' );

	# remove some files
	my @files = @ARGV = ( File::Spec->catfile( 'ecmddir', 'ecmdfile' ),
	File::Spec->catfile( 'ecmddir', 'temp2', 'ecmdfile' ) );
	rm_f();

	ok( ! -e $_, "removed $_ successfully" ) for (@ARGV);

	# rm_f dir
	@ARGV = my $dir = File::Spec->catfile( 'ecmddir' );
	rm_rf();
	ok( ! -e $dir, "removed $dir successfully" );
}

END {
	1 while unlink 'ecmdfile';
	File::Path::rmtree( 'ecmddir' );
}

package TieOut;

sub TIEHANDLE {
	bless( \(my $text), $_[0] );
}

sub PRINT {
	${ $_[0] } .= join($/, @_);
}
