package Carp;

# This package implements handy routines for modules that wish to throw
# exceptions outside of the current package.

$CarpLevel = 0;		# How many extra package levels to skip on carp.

require Exporter;
@ISA = Exporter;
@EXPORT = qw(confess croak carp);

sub longmess {
    my $error = shift;
    my $mess = "";
    my $i = 1 + $CarpLevel;
    my ($pack,$file,$line,$sub);
    while (($pack,$file,$line,$sub) = caller($i++)) {
	$mess .= "\t$sub " if $error eq "called";
	$mess .= "$error at $file line $line\n";
	$error = "called";
    }
    $mess || $error;
}

sub shortmess {	# Short-circuit &longmess if called via multiple packages
    my $error = $_[0];	# Instead of "shift"
    my ($curpack) = caller(1);
    my $extra = $CarpLevel;
    my $i = 2;
    my ($pack,$file,$line,$sub);
    while (($pack,$file,$line,$sub) = caller($i++)) {
	if ($pack ne $curpack) {
	    if ($extra-- > 0) {
		$curpack = $pack;
	    }
	    else {
		return "$error at $file line $line\n";
	    }
	}
    }
    goto &longmess;
}

sub confess { die longmess @_; }
sub croak { die shortmess @_; }
sub carp { warn shortmess @_; }

1;
