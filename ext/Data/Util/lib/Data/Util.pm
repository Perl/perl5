package Data::Util;

require Exporter;
require DynaLoader;

our @ISA        = qw(Exporter DynaLoader);
our @EXPORT_OK  = qw(sv_readonly_flag);
our $VERSION    = 0.04;

bootstrap Data::Util $VERSION;

1;

__END__

=head1 NAME

Data::Util - A selection of general-utility data subroutines

=head1 SYNOPSIS

  use Data::Util qw(sv_readonly_flag);

  my $sv_readonly = sv_readonly_flag(%some_data);

  sv_readonly_flag(@some_data, 1);  # Set the sv_readonly flag on
                                    # @some_data to true.

=head1 DESCRIPTION

C<Data::Util> contains a selection of subroutines which are useful on
scalars, hashes and lists (and thus wouldn't fit into Scalar, Hash or
List::Util).  All of the routines herein will work equally well on a
scalar, hash, list or even hash & list elements.

    sv_readonly_flag($some_data);
    sv_readonly_flag(@some_data);
    sv_readonly_flag(%some_data);
    sv_readonly_flag($some_data{key});
    sv_readonly_flag($some_data[3]);

We'll just refer to the conglomeration as "DATA".

By default C<Data::Util> does not export any subroutines.  You can ask
for...

=over 4

=item sv_readonly_flag

  my $sv_readonly = sv_readonly_flag(DATA);
  sv_readonly_flag(DATA, 1);    # set sv_readonly true
  sv_readonly_flag(DATA, 0);    # set sv_readonly false

This gets/sets the sv_readonly flag on the given DATA.  When setting
it returns the previous state of the flag.  This is intended for
people I<that know what they're doing.>

The exact behavior exhibited by a piece of DATA when sv_readonly is
set depends on what type of data it is.  B<It doesn't even necessarily
make the data readonly!>  Look for specific functions in Scalar::Util,
List::Util and Hash::Util for making those respective types readonly.

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> using XS code by Nick Ing-Simmons.

=head1 SEE ALSO

L<Scalar::Util>, L<List::Util>, L<Hash::Util>

=cut

