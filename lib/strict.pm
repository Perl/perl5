package strict;

sub bits {
    my $bits = 0;
    foreach $sememe (@_) {
	$bits |= 0x00000002 if $sememe eq 'refs';
	$bits |= 0x00000200 if $sememe eq 'subs';
	$bits |= 0x00000400 if $sememe eq 'vars';
    }
    $bits;
}

sub import {
    shift;
    $^H |= bits(@_ ? @_ : qw(refs subs vars));
}

sub unimport {
    shift;
    $^H &= ~ bits(@_ ? @_ : qw(refs subs vars));
}

1;
