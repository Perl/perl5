package O;
use B qw(minus_c);
use Carp;    

sub import {
    my ($class, $backend, @options) = @_;
    eval "use B::$backend ()";
    if ($@) {
	croak "use of backend $backend failed: $@";
    }
    my $compilesub = &{"B::${backend}::compile"}(@options);
    if (ref($compilesub) eq "CODE") {
	minus_c;
	eval 'END { &$compilesub() }';
    } else {
	die $compilesub;
    }
}

1;

__END__

=head1 NAME

O - Generic interface to Perl Compiler backends

=head1 SYNOPSIS

	perl -MO=Backend[,OPTIONS] foo.pl

=head1 DESCRIPTION

See F<ext/B/README>.

=head1 AUTHOR

Malcolm Beattie, C<mbeattie@sable.ox.ac.uk>

=cut
