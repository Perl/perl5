package TieHash;
use Carp;

sub new {
    my $pack = shift;
    $pack->TIEHASH(@_);
}

# Grandfather "new"

sub TIEHASH {
    my $pack = shift;
    if (defined &{"{$pack}::new"}) {
	carp "WARNING: calling ${pack}->new since ${pack}->TIEHASH is missing"
	    if $^W;
	$pack->new(@_);
    }
    else {
	croak "$pack doesn't define a TIEHASH method";
    }
}

sub EXISTS {
    my $pack = ref $_[0];
    croak "$pack doesn't define an EXISTS method";
}

sub CLEAR {
    my $self = shift;
    my $key = $self->FIRSTKEY(@_);
    my @keys;

    while (defined $key) {
	push @keys, $key;
	$key = $self->NEXTKEY(@_, $key);
    }
    foreach $key (@keys) {
	$self->DELETE(@_, $key);
    }
}

1;
