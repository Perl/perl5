# For testing Test::More;
package Test::Simple::Catch::More;

my $out = tie *Test::Simple::TESTOUT, __PACKAGE__;
tie *Test::More::TESTOUT, __PACKAGE__, $out;
my $err = tie *Test::More::TESTERR, __PACKAGE__;
tie *Test::Simple::TESTERR, __PACKAGE__, $err;

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
