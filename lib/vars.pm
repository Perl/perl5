package vars;

=head1 NAME

vars - Perl pragma to predeclare global variable names

=head1 SYNOPSIS

    use vars qw($frob @mung %seen);

=head1 DESCRIPTION

This will predeclare all the variables whose names are 
in the list, allowing you to use them under "use strict", and
disabling any typo warnings.

Unlike pragmas that affect the C<$^H> hints variable, the C<use vars> and
C<use subs> declarations are not BLOCK-scoped.  They are thus effective
for the entire file in which they appear.  You may not rescind such
declarations with C<no vars> or C<no subs>.

Packages such as the B<AutoLoader> and B<SelfLoader> that delay
loading of subroutines within packages can create problems with
package lexicals defined using C<my()>. While the B<vars> pragma
cannot duplicate the effect of package lexicals (total transparency
outside of the package), it can act as an acceptable substitute by
pre-declaring global symbols, ensuring their availability to the
later-loaded routines.

See L<perlmod/Pragmatic Modules>.

=cut

require 5.002;
use Carp;

sub import {
    my $callpack = caller;
    my ($pack, @imports, $sym, $ch) = @_;
    foreach $sym (@imports) {
	croak "Can't declare another package's variables" if $sym =~ /::/;
        ($ch, $sym) = unpack('a1a*', $sym);
        *{"${callpack}::$sym"} =
          (  $ch eq "\$" ? \$   {"${callpack}::$sym"}
           : $ch eq "\@" ? \@   {"${callpack}::$sym"}
           : $ch eq "\%" ? \%   {"${callpack}::$sym"}
           : $ch eq "\*" ? \*   {"${callpack}::$sym"}
           : $ch eq "\&" ? \&   {"${callpack}::$sym"}
           : croak "'$ch$sym' is not a valid variable name\n");
    }
};

1;
