# For testing Test::Simple;
package Catch;

my $out = tie *Test::Simple::TESTOUT, 'Catch';
my $err = tie *Test::Simple::TESTERR, 'Catch';

# We have to use them to shut up a "used only once" warning.
() = (*Test::Simple::TESTOUT, *Test::Simple::TESTERR);

sub caught { return $out, $err }

# Prevent Test::Simple from exiting in its END block.
*Test::Simple::exit = sub {};

sub PRINT  {
    my $self = shift;
    $$self .= join '', @_;
}

sub TIEHANDLE {
    my $class = shift;
    my $self = '';
    return bless \$self, $class;
}
sub READ {}
sub READLINE {}
sub GETC {}

1;
