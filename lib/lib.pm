package lib;

@ORIG_INC = ();		# (avoid typo warning)
@ORIG_INC = @INC;	# take a handy copy of 'original' value


sub import {
    shift;
    unshift(@INC, @_);
}


sub unimport {
    shift;
    my $mode = shift if $_[0] =~ m/^:[A-Z]+/;

    my %names;
    foreach(@_) { ++$names{$_} };

    if ($mode and $mode eq ':ALL') {
	# Remove ALL instances of each named directory.
	@INC = grep { !exists $names{$_} } @INC;
    } else {
	# Remove INITIAL instance(s) of each named directory.
	@INC = grep { --$names{$_} < 0   } @INC;
    }
}

__END__

=head1 NAME

lib - manipulate @INC at compile time

=head1 SYNOPSIS

    use lib LIST;

    no lib LIST;

=head1 DESCRIPTION

This is a small simple module which simplifies the manipulation of @INC
at compile time.

It is typically used to add extra directories to perl's search path so
that later C<use> or C<require> statements will find modules which are
not located on perl's default search path.


=head2 ADDING DIRECTORIES TO @INC

The parameters to C<use lib> are added to the start of the perl search
path. Saying

    use lib LIST;

is the same as saying

    BEGIN { unshift(@INC, LIST) }


=head2 DELETING DIRECTORIES FROM @INC

You should normally only add directories to @INC.  If you need to
delete directories from @INC take care to only delete those which you
added yourself or which you are certain are not needed by other modules
in your script.  Other modules may have added directories which they
need for correct operation.

By default the C<no lib> statement deletes the I<first> instance of
each named directory from @INC.  To delete multiple instances of the
same name from @INC you can specify the name multiple times.

To delete I<all> instances of I<all> the specified names from @INC you can
specify ':ALL' as the first parameter of C<no lib>. For example:

    no lib qw(:ALL .);


=head2 RESTORING ORIGINAL @INC

When the lib module is first loaded it records the current value of @INC
in an array C<@lib::ORIG_INC>. To restore @INC to that value you
can say either

    @INC = @lib::ORIG_INC;

or

    no  lib @INC;
    use lib @lib::ORIG_INC;

=head1 SEE ALSO

AddINC - optional module which deals with paths relative to the source file.

=head1 AUTHOR

Tim Bunce, 2nd June 1995.

=cut

