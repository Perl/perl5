package V;

use Getopt::Std 'getopts';
getopts('vp:');

require Exporter;
@ISA = 'Exporter';

@EXPORT = qw( dprofpp $opt_v $results $expected report @results );
@EXPORT_OK = qw( notok ok $num );

my $out = 0;
$num = 0;
$results = $expected = '';
$perl = $opt_p || $^X;

print "\nperl: $perl\n" if $opt_v;
if( ! -f $perl ){ die "Where's Perl?" }

sub dprofpp {
	my $switches = shift;

	open( D, "$perl ../dprofpp $switches 2> err |" ) || warn "$0: Can't run. $!\n";
	@results = <D>;
	close D;

	open( D, "<err" ) || warn "$0: Can't open: $!\n";
	@err = <D>;
	close D;
	push( @results, @err ) if @err;

	$results = qq{@results};
	# ignore Loader (Dyna/Auto etc), leave newline
	$results =~ s/^\w+Loader::import//;
	$results =~ s/\n /\n/gm;
	$results;
}

sub report {
	$num = shift;
	my $sub = shift;
	my $x;

	$x = &$sub;
	$x ? &ok : &notok;
}

sub ok {
	++$out;
	print "ok $num, ";
}

sub notok {
	++$out;
	print "not ok $num, ";
	if( $opt_v ){
		print "\nResult\n{$results}\n";
		print "Expected\n{$expected}\n";
	}
}

END { print "\n" if $out }


1;
