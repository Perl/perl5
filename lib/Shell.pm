package Shell;

sub import {
    my $self = shift;
    my ($callpack, $callfile, $callline) = caller;
    my @EXPORT;
    if (@_) {
	@EXPORT = @_;
    }
    else {
	@EXPORT = 'AUTOLOAD';
    }
    foreach $sym (@EXPORT) {
        *{"${callpack}::$sym"} = \&{"Shell::$sym"};
    }
};

AUTOLOAD {
    my $cmd = $AUTOLOAD;
    $cmd =~ s/^.*:://;
    eval qq {
	sub $AUTOLOAD {
	    if (\@_ < 2) {
		`$cmd \@_`;
	    }
	    else {
		open(SUBPROC, "-|")
			or exec '$cmd', \@_
			or die "Can't exec $cmd: \$!\n";
		if (wantarray) {
		    my \@ret = <SUBPROC>;
		    close SUBPROC;	# XXX Oughta use a destructor.
		    \@ret;
		}
		else {
		    local(\$/) = undef;
		    my \$ret = <SUBPROC>;
		    close SUBPROC;
		    \$ret;
		}
	    }
	}
    };
    goto &$AUTOLOAD;
}

1;
