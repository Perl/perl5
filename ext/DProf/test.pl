# perl

require 5.003;

use Benchmark qw( timediff timestr );
use Getopt::Std 'getopts';
use Config '%Config';
getopts('vI:p:');

# -v   Verbose
# -I   Add to @INC
# -p   Name of perl binary

unless (-r 'dprofpp' and -M 'dprofpp' <= -M 'dprofpp.PL') {
  print STDERR "dprofpp out of date, extracting...\n";
  system 'perl', 'dprofpp.PL' and die 'perl dprofpp.PL: exit code $?, $!';
}
die "Need dprofpp, could not make it" unless -r 'dprofpp';

chdir( 't' ) if -d 't';
@tests = @ARGV ? @ARGV : sort <*.t *.v>;  # glob-sort, for OS/2

$path_sep = $Config{path_sep} || ':';
if( -d '../blib' ){
	unshift @INC, '../blib/arch', '../blib/lib';
}
$perl5lib = $opt_I || join( $path_sep, @INC );
$perl = $opt_p || $^X;

if( $opt_v ){
	print "tests: @tests\n";
	print "perl: $perl\n";
	print "perl5lib: $perl5lib\n";
}
if( $perl =~ m|^\./| ){
	# turn ./perl into ../perl, because of chdir(t) above.
	$perl = ".$perl";
}
if( ! -f $perl ){ die "Where's Perl?" }

sub profile {
	my $test = shift;
	my @results;
	local $ENV{PERL5LIB} = $perl5lib;
	my $opt_d = '-d:DProf';

	my $t_start = new Benchmark;
	open( R, "$perl $opt_d $test |" ) || warn "$0: Can't run. $!\n";
	@results = <R>;
	close R;
	my $t_total = timediff( new Benchmark, $t_start );

	if( $opt_v ){
		print "\n";
		print @results
	}

	print timestr( $t_total, 'nop' ), "\n";
}


sub verify {
	my $test = shift;

	system $perl, '-I.', $test, $opt_v?'-v':'', '-p', $perl;
}


$| = 1;
while( @tests ){
	$test = shift @tests;
	print $test . '.' x (20 - length $test);
	if( $test =~ /t$/ ){
		profile $test;
	}
	else{
		verify $test;
	}
}
