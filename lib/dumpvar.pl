package dumpvar;

# translate control chars to ^X - Randal Schwartz
sub unctrl {
	local($_) = @_;
	return \$_ if ref \$_ eq "GLOB";
	s/([\001-\037\177])/'^'.pack('c',ord($1)^64)/eg;
	$_;
}
sub main'dumpvar {
    ($package,@vars) = @_;
    $package .= "::" unless $package =~ /::$/;
    *stab = *{"main::"};
    while ($package =~ /(\w+?::)/g){
	*stab = ${stab}{$1};
    }
    while (($key,$val) = each(%stab)) {
	{
	    next if @vars && !grep($key eq $_,@vars);
	    local(*entry) = $val;
	    if (defined $entry) {
		print "\$",&unctrl($key)," = '",&unctrl($entry),"'\n";
	    }
	    if (defined @entry) {
		print "\@$key = (\n";
		foreach $num ($[ .. $#entry) {
		    print "  $num\t'",&unctrl($entry[$num]),"'\n";
		}
		print ")\n";
	    }
	    if ($key ne "main::" && $key ne "DB::" && defined %entry
		&& !($package eq "dumpvar" and $key eq "stab")) {
		print "\%$key = (\n";
		foreach $key (sort keys(%entry)) {
		    print "  $key\t'",&unctrl($entry{$key}),"'\n";
		}
		print ")\n";
	    }
	}
    }
}

1;
