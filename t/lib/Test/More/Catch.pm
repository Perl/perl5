# For testing Test::More;
package Catch;

my $out = tie *Test::Simple::TESTOUT, 'Catch';
tie *Test::More::TESTOUT, 'Catch', $out;
my $err = tie *Test::More::TESTERR, 'Catch';
tie *Test::Simple::TESTERR, 'Catch', $err;

# We have to use them to shut up a "used only once" warning.
() = (*Test::More::TESTOUT, *Test::More::TESTERR);

sub caught { return $out, $err }


sub PRINT  {
    my $self = shift;
    $$self .= join '', @_;
}

sub TIEHANDLE {
    my($class, $self) = @_;
    my $foo = '';
    $self = $self || \$foo;
    return bless $self, $class;
}
sub READ {}
sub READLINE {}
sub GETC {}

1;
