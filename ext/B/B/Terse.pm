package B::Terse;
use B::Concise;

sub compile {
    my @args = @_;
    $args[0] = "-exec" if $args[0] eq "exec";
    unshift @args, "-terse";
    B::Concise::compile(@args);
}

1;

__END__

=head1 NAME

B::Terse - Walk Perl syntax tree, printing terse info about ops

=head1 SYNOPSIS

    perl -MO=Terse[,OPTIONS] foo.pl

=head1 DESCRIPTION

This version of B::Terse is really just a wrapper that calls B::Concise
with the B<-terse> option. It is provided for compatibility with old scripts
(and habits) but using B::Concise directly is now recommended instead.

=head1 AUTHOR

The original version of B::Terse was written by Malcolm Beattie,
C<mbeattie@sable.ox.ac.uk>. This wrapper was written by Stephen McCamant,
C<smcc@CSUA.Berkeley.EDU>.

=cut
