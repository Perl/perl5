package ISA;
use Carp;

sub import {
    my $class = shift;
    my ($package) = caller;
    foreach my $base (@_) {
	croak qq(No such class "$base") unless defined %{"$base\::"};
	eval {
	    $base->ISA($package);
	};
	if ($@ && $@ !~ /^Can't locate object method/) {
	    $@ =~ s/ at .*? line \d+\n$//;
	    croak $@;
	}
    }
    push(@{"$package\::ISA"}, @_);
}

1;
