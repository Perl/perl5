package Tie::Hash::NamedCapture;

use strict;
use warnings;

our $VERSION = "0.03";

sub TIEHASH {
    my $classname = shift;
    my $hash = {@_};

    if ($hash->{re} && !re::is_regexp($hash->{re})) {
        die "'re' parameter to ",__PACKAGE__,"->TIEHASH must be a qr//"
    }

    return bless $hash, $classname;
}

sub FETCH {
    return re::regname($_[1],$_[0]->{re},$_[0]->{all});
}

sub STORE {
    require Carp;
    Carp::croak("STORE forbidden: hashes tied to ",__PACKAGE__," are read-only.");
}

sub FIRSTKEY {
    re::regnames_iterinit($_[0]->{re});
    return $_[0]->NEXTKEY;
}

sub NEXTKEY {
    return re::regnames_iternext($_[0]->{re},$_[0]->{all});
}

sub EXISTS {
    return defined re::regname( $_[1], $_[0]->{re},$_[0]->{all});
}

sub DELETE {
    require Carp;
    Carp::croak("DELETE forbidden: hashes tied to ",__PACKAGE__," are read-only");
}

sub CLEAR {
    require Carp;
    Carp::croak("CLEAR forbidden: hashes tied to ",__PACKAGE__," are read-only");
}

sub SCALAR {
    return scalar re::regnames($_[0]->{re},$_[0]->{all});
}

1;

__END__

=head1 NAME

Tie::Hash::NamedCapture - Named regexp capture buffers

=head1 SYNOPSIS

    tie my %hash, "Tie::Hash::NamedCapture";
    # %hash now behaves like %+

    tie my %hash, "Tie::Hash::NamedCapture", re => $qr, all => 1;
    # %hash now access buffers from regexp in $qr like %-

=head1 DESCRIPTION

This module is used to implement the special hashes C<%+> and C<%->, but it
can be used independently.

When the C<re> parameter is set to a C<qr//> expression, then the tied
hash is bound to that particular regexp and will return the results of its
last successful match. If the parameter is omitted, then the hash behaves
just as C<$1> does by referencing the last successful match in the
currently active dynamic scope.

When the C<all> parameter is provided, then the tied hash elements will be
array refs listing the contents of each capture buffer whose name is the
same as the associated hash key. If none of these buffers were involved in
the match, the contents of that array ref will be as many C<undef> values
as there are capture buffers with that name. In other words, the tied hash
will behave as C<%->.

When the C<all> parameter is omitted or false, then the tied hash elements
will be the contents of the leftmost defined buffer with the name of the
associated hash key. In other words, the tied hash will behave as
C<%+>.

The keys of C<%->-like hashes correspond to all buffer names found in the
regular expression; the keys of C<%+>-like hashes list only the names of
buffers that have captured (and that are thus associated to defined values).

For instance:

    my $qr = qr/(?<foo>bar)/;
    if ( 'bar' =~ $qr ) {
        tie my %hash, "Tie::Hash::NamedCapture", re => $qr;
        print $+{foo};    # prints "bar"
        print $hash{foo}; # prints "bar" too
        if ( 'bar' =~ /bar/ ) {
            # last successful match is now different
            print $+{foo};    # prints nothing (undef)
            print $hash{foo}; # still prints "bar"
        }
    }

=head1 SEE ALSO

L<re>, L<perlmodlib/Pragmatic Modules>, L<perlvar/"%+">, L<perlvar/"%-">.

=cut
