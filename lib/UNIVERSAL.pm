package UNIVERSAL;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(isa);

1;
__END__

=head1 NAME

UNIVERSAL - base class for ALL classes (blessed references)

=head1 SYNOPSIS

    use UNIVERSAL qw(isa);

    $yes = isa($ref, "HASH");
    $io = $fd->isa("IO::Handle");
    $sub = $obj->can('print');

=head1 DESCRIPTION

C<UNIVERSAL> is the base class which all bless references will inherit from,
see L<perlobj>

C<UNIVERSAL> provides the following methods

=over 4

=item isa ( TYPE )

C<isa> returns I<true> if C<REF> is blessed into package C<TYPE>
or inherits from package C<TYPE>.

C<isa> can be called as either a static or object method call.

=item can ( METHOD )

C<can> checks if the object has a method called C<METHOD>. If it does
then a reference to the sub is returned. If it does not then I<undef>
is returned.

C<can> can be called as either a static or object method call.

=item VERSION ( [ REQUIRE ] )

C<VERSION> will return the value of the variable C<$VERSION> in the
package the object is blessed into. If C<REQUIRE> is given then
it will do a comparison and die if the package version is not
greater than or equal to C<REQUIRE>.

C<VERSION> can be called as either a static or object method call.

=back

C<UNIVERSAL> also optionally exports the following subroutines

=over 4

=item isa ( REF, TYPE )

C<isa> returns I<true> if the first argument is a reference and either
of the following statements is true.

=over 8

=item

C<REF> is a blessed reference and is blessed into package C<TYPE>
or inherits from package C<TYPE>

=item

C<REF> is a reference to a C<TYPE> of perl variable (er 'HASH')

=back

=back

=cut
