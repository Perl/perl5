;# getopts.pl - a better getopt.pl

;# Usage:
;#      do Getopts('a:bc');  # -a takes arg. -b & -c not. Sets opt_* as a
;#                           #  side effect.

sub Getopts {
    local($argumentative) = @_;
    local(@args,$_,$first,$rest);

    @args = split( / */, $argumentative );
    while(($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
	($first,$rest) = ($1,$2);
	$pos = index($argumentative,$first);
	if($pos >= $[) {
	    if($args[$pos+1] eq ':') {
		shift;
		if($rest eq '') {
		    $rest = shift;
		}
		eval "\$opt_$first = \$rest;";
	    }
	    else {
		eval "\$opt_$first = 1";
		if($rest eq '') {
		    shift;
		}
		else {
		    $ARGV[0] = "-$rest";
		}
	    }
	}
	else {
	    print stderr "Unknown option: $first\n";
	    if($rest ne '') {
		$ARGV[0] = "-$rest";
	    }
	    else {
		shift;
	    }
	}
    }
}

1;
