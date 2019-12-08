package Hoisted;
use XS::APItest;
use Carp;

XS::APItest::create_hoisted_subs(<<'CODE');
sub getline {
    @_ == 1 or croak 'usage: $io->getline()';
    my $this = shift;
    return scalar <$this>;
}

sub getlines {
    @_ == 1 or croak 'usage: $io->getlines()';
    wantarray or
	croak 'Can\'t call $io->getlines in a scalar context, use $io->getline';
    my $this = shift;
    return <$this>;
}

1;
CODE

1;
