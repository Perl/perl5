;# $Header: getopt.pl,v 2.0 88/06/05 00:16:22 root Exp $

;# Process single-character switches with switch clustering.  Pass one argument
;# which is a string containing all switches that take an argument.  For each
;# switch found, sets $opt_x (where x is the switch name) to the value of the
;# argument, or 1 if no argument.  Switches which take an argument don't care
;# whether there is a space between the switch and the argument.

;# Usage:
;#	do Getopt('oDI');  # -o, -D & -I take arg.  Sets opt_* as a side effect.

sub Getopt {
    local($argumentative) = @_;
    local($_,$first,$rest);

    while (($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
	($first,$rest) = ($1,$2);
	if (index($argumentative,$first) >= $[) {
	    if ($rest ne '') {
		shift;
	    }
	    else {
		shift;
		$rest = shift;
	    }
	    eval "\$opt_$first = \$rest;";
	}
	else {
	    eval "\$opt_$first = 1;";
	    if ($rest ne '') {
		$ARGV[0] = "-$rest";
	    }
	    else {
		shift;
	    }
	}
    }
}
