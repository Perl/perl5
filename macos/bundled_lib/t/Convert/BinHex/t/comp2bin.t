use lib "./blib/lib", "./lib", "./t";

use Checker;
use Convert::BinHex;

%TEST = (
	 PIVOT_3 => {
	     COMP => ["90 00 01 02 03 04 00", 
		      "90 00 03"],
	     BIN  => "90 01 02 03 04 00 90 03",
	 },
	 PIVOT_2 => {
	     COMP => ["90 00 01 02 03 04 00 90", 
		      "00 03"],
	     BIN  => "90 01 02 03 04 00 90 03",
	 },
	 PIVOT_1 => {
	     COMP => ["90 00 01 02 03 04 00 90 00", 
		      "03"],
	     BIN  => "90 01 02 03 04 00 90 03",
	 },
	 CHOPPY => {
	     COMP => ["90",
		      "00",
		      "01 02 03 04",
		      "00", 
		      "90",
		      "00",
		      "03"],
	     BIN  => "90 01 02 03 04 00 90 03",
	 },
	 FOUR_FIVES => {
	     COMP => ["01 02 03 04 05 90 04"],
	     BIN  => "01 02 03 04 05 05 05 05",
	 },
	 FOUR_FIVES_AND_A_SIX => {
	     COMP => ["01 02 03 04 05 90 04 06"],
	     BIN  => "01 02 03 04 05 05 05 05 06",
	 },
	 FOUR_MARKS => {
	     COMP => ["01 02 03 04 90 00 90 04"],
	     BIN  => "01 02 03 04 90 90 90 90",
	 },
	 FOUR_MARKS_AND_A_SIX => {
	     COMP => ["01 02 03 04 90 00 90 04 06"],
	     BIN  => "01 02 03 04 90 90 90 90 06",
	 },
	 FIVE_ONES_AND_TWOS => {
	     COMP => ["01 90 05 02 90 05"],
	     BIN  => "01 01 01 01 01 02 02 02 02 02",
	 },
	 );	
	
sub str2hex {
	my $str = shift;
	eval '"\x' . join('\x', split(/\s+/,$str)) . '"';
}

#------------------------------------------------------------
# BEGIN
#------------------------------------------------------------
print "1..9\n";
my $TESTKEY;
foreach $TESTKEY (sort keys %TEST) {
    my $test = $TEST{$TESTKEY};
    my @comps = map { str2hex($_) } @{$test->{COMP}};
    my $bin  = str2hex($test->{BIN});
    
    my $comp;
    my $rbin = '';
    my $H2B = Convert::BinHex->hex2bin;
    foreach $comp (@comps) {
	$rbin .= $H2B->comp2bin_next($comp);
    }
    check(($rbin eq $bin), "test $TESTKEY");
}
1;








