package Carp;

# This package implements handy routines for modules that wish to throw
# exceptions outside of the current package.

require Exporter;
@ISA = Exporter;
@EXPORT = qw(confess croak carp);

sub longmess {
    my $error = shift;
    my $mess = "";
    my $i = 2;
    my ($pack,$file,$line,$sub);
    while (($pack,$file,$line,$sub) = caller($i++)) {
	$mess .= "\t$sub " if $error eq "called";
	$mess .= "$error at $file line $line\n";
	$error = "called";
    }
    $mess || $error;
}

sub shortmess {
    my $error = shift;
    my ($curpack) = caller(1);
    my $i = 2;
    my ($pack,$file,$line,$sub);
    while (($pack,$file,$line,$sub) = caller($i++)) {
	return "$error at $file line $line\n" if $pack ne $curpack;
    }
    longmess $error;
}

sub confess { die longmess @_; }
sub croak { die shortmess @_; }
sub carp { warn shortmess @_; }

