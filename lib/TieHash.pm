package TieHash;
use Carp;

sub new {
    my $pack = shift;
    $pack->TIEHASH(@_);
}

# Grandfather "new"

sub TIEHASH {
    my $pack = shift;
    if (defined &{"$pack\::new"}) {
	carp "WARNING: calling $pack\->new since $pack\->TIEHASH is missing"
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

# The TieHash::Std package implements standard perl hash behaviour.
# It exists to act as a base class for classes which only wish to
# alter some parts of their behaviour.

package TieHash::Std;
@ISA = qw(TieHash);

sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }

1;
