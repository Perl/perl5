package Shell;

use Config;

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
	    if (\@_ < 1) {
		`$cmd`;
	    }
	    elsif (\$Config{'archname'} eq 'os2') {
		local(\*SAVEOUT, \*READ, \*WRITE);

		open SAVEOUT, '>&STDOUT' or die;
		pipe READ, WRITE or die;
		open STDOUT, '>&WRITE' or die;
		close WRITE;

		my \$pid = system(1, \$cmd, \@_);
		die "Can't execute $cmd: \$!\n" if \$pid < 0;

		open STDOUT, '>&SAVEOUT' or die;
		close SAVEOUT;

		if (wantarray) {
		    my \@ret = <READ>;
		    close READ;
		    waitpid \$pid, 0;
		    \@ret;
		}
		else {
		    local(\$/) = undef;
		    my \$ret = <READ>;
		    close READ;
		    waitpid \$pid, 0;
		    \$ret;
		}
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
