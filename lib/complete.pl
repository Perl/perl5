;#
;#	@(#)complete.pl	1.0 (sun!waynet) 11/11/88
;#
;# Author: Wayne Thompson
;#
;# Description:
;#     This routine provides word completion.
;#     (TAB) attempts word completion.
;#     (^D)  prints completion list.
;#	(These may be changed by setting $Complete'complete, etc.)
;#
;# Diagnostics:
;#     Bell when word completion fails.
;#
;# Dependencies:
;#     The tty driver is put into raw mode.
;#
;# Bugs:
;#
;# Usage:
;#     $input = do Complete('prompt_string', @completion_list);
;#

CONFIG: {
    package Complete;

    $complete =	"\004";
    $kill =	"\025";
    $erase1 =	"\177";
    $erase2 =	"\010";
}

sub Complete {
    package Complete;

    local ($prompt) = shift (@_);
    local ($c, $cmp, $l, $r, $ret, $return, $test);
    @_cmp_lst = sort @_;
    local($[) = 0;
    system 'stty raw -echo';
    loop: {
	print $prompt, $return;
	while (($c = getc(stdin)) ne "\r") {
	    if ($c eq "\t") {			# (TAB) attempt completion
		@_match = ();
		foreach $cmp (@_cmp_lst) {
		    push (@_match, $cmp) if $cmp =~ /^$return/;
		}
    	    	$test = $_match[0];
    	    	$l = length ($test);
		unless ($#_match == 0) {
    	    	    shift (@_match);
    	    	    foreach $cmp (@_match) {
    	    	    	until (substr ($cmp, 0, $l) eq substr ($test, 0, $l)) {
    	    	    	    $l--;
    	    	    	}
    	    	    }
    	    	    print "\007";
    	    	}
    	    	print $test = substr ($test, $r, $l - $r);
    	    	$r = length ($return .= $test);
	    }
	    elsif ($c eq $complete) {		# (^D) completion list
		print "\r\n";
		foreach $cmp (@_cmp_lst) {
		    print "$cmp\r\n" if $cmp =~ /^$return/;
		}
		redo loop;
	    }
    	    elsif ($c eq $kill && $r) {	# (^U) kill
    	    	$return = '';
    	    	$r = 0;
    	    	print "\r\n";
    	    	redo loop;
    	    }
	    	    	    	    	    	# (DEL) || (BS) erase
	    elsif ($c eq $erase1 || $c eq $erase2) {
		if($r) {
		    print "\b \b";
		    chop ($return);
		    $r--;
		}
	    }
	    elsif ($c =~ /\S/) {    	    	# printable char
		$return .= $c;
		$r++;
		print $c;
	    }
	}
    }
    system 'stty -raw echo';
    print "\n";
    $return;
}

1;
