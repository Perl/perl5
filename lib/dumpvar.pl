package dumpvar;

sub main'dumpvar {
    ($package) = @_;
    local(*stab) = eval("*_$package");
    while (($key,$val) = each(%stab)) {
	{
	    local(*entry) = $val;
	    if (defined $entry) {
		print "\$$key = '$entry'\n";
	    }
	    if (defined @entry) {
		print "\@$key = (\n";
		foreach $num ($[ .. $#entry) {
		    print "  $num\t'",$entry[$num],"'\n";
		}
		print ")\n";
	    }
	    if ($key ne "_$package" && defined %entry) {
		print "\%$key = (\n";
		foreach $key (sort keys(%entry)) {
		    print "  $key\t'",$entry{$key},"'\n";
		}
		print ")\n";
	    }
	}
    }
}
