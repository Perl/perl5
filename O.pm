package O;
use B qw(minus_c);
use Carp;    

my $compilesub;

sub import {
    my ($class, $backend, @options) = @_;
    eval "use B::$backend ()";
    if ($@) {
	croak "use of backend $backend failed: $@";
    }
    $compilesub = &{"B::${backend}::compile"}(@options);
    if (ref($compilesub) eq "CODE") {
	minus_c;
	eval 'END { &$compilesub() }';
    } else {
	die $compilesub;
    }
}

1;

