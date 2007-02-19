package re::Tie::Hash::NamedCapture;
use strict;
use warnings;
our $VERSION     = "0.01";
use re qw(is_regexp
          regname
          regnames
          regnames_count
          regnames_iterinit
          regnames_iternext);

sub TIEHASH {
    my $classname = shift;
    my $hash = {@_};

    if ($hash->{re} && !is_regexp($hash->{re})) {
        die "'re' parameter to ",__PACKAGE__,"->TIEHASH must be a qr//"
    }

    return bless $hash, $classname;
}

sub FETCH {
    return regname($_[1],$_[0]->{re},$_[0]->{all});
}

sub STORE {
    require Carp;
    Carp::croak("STORE forbidden: Hashes tied to ",__PACKAGE__," are read/only.");
}

sub FIRSTKEY {
    regnames_iterinit($_[0]->{re});
    return $_[0]->NEXTKEY;
}

sub NEXTKEY {
    return regnames_iternext($_[0]->{re},$_[0]->{all});
}

sub EXISTS {
    return defined regname( $_[1], $_[0]->{re},$_[0]->{all});
}

sub DELETE {
    require Carp;
    Carp::croak("DELETE forbidden: Hashes tied to ",__PACKAGE__," are read/only");
}

sub CLEAR {
    require Carp;
    Carp::croak("CLEAR forbidden: Hashes tied to ",__PACKAGE__," are read/only");
}

sub SCALAR {
    return scalar regnames($_[0]->{re},$_[0]->{all});
}

1;

__END__

=head1 NAME

re::Tie::Hash::NamedCapture - Perl module to support named regex capture buffers

=head1 SYNOPSIS

    tie my %hash,"re::Tie::Hash::NamedCapture";
    # %hash now behaves like %-

    tie my %hash,"re::Tie::Hash::NamedCapture",re => $qr, all=> 1,
    # %hash now access buffers from regex in $qr like %+

=head1 DESCRIPTION

Implements the behaviour required for C<%+> and C<%-> but can be used
independently.

When the C<re> parameter is provided, and the value is the result of
a C<qr//> expression then the hash is bound to that particular regexp
and will return the results of its last successful match. If the
parameter is omitted then the hash behaves just as C<$1> does by
referencing the last successful match.

When the C<all> parameter is provided then the result of a fetch
is an array ref containing the contents of each buffer whose name
was the same as the key used for the access. If the buffer wasn't
involved in the match then an undef will be stored. When the all
parameter is omitted or not a true value then the return will be
a the content of the left most defined buffer with the given name.
If there is no buffer with the desired name defined then C<undef>
is returned.


For instance:

    my $qr = qr/(?<foo>bar)/;
    if ( 'bar' =~ /$qr/ ) {
        tie my %hash,"re::Tie::Hash::NamedCapture",re => $qr, all => 1;
        if ('bar'=~/bar/) {
            # last successful match is now different
            print $hash{foo}; # prints foo
        }
    }

=head1 SEE ALSO

L<re>, L<perlmodlib/Pragmatic Modules>.

=cut
