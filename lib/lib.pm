package lib;

use 5.005_64;
use Config;

my $archname = $Config{'archname'};
my $ver = $Config{'version'};

our @ORIG_INC = @INC;	# take a handy copy of 'original' value
our $VERSION = '0.5564';

sub import {
    shift;

    my %names;
    foreach (reverse @_) {
	if ($_ eq '') {
	    require Carp;
	    Carp::carp("Empty compile time value given to use lib");
	}
	if (-e && ! -d _) {
	    require Carp;
	    Carp::carp("Parameter to use lib must be directory, not file");
	}
	unshift(@INC, $_);
	# Put a corresponding archlib directory infront of $_ if it
	# looks like $_ has an archlib directory below it.
	if (-d "$_/$archname") {
	    unshift(@INC, "$_/$archname")    if -d "$_/$archname/auto";
	    unshift(@INC, "$_/$archname/$ver") if -d "$_/$archname/$ver/auto";
	}
    }

    # remove trailing duplicates
    @INC = grep { ++$names{$_} == 1 } @INC;
    return;
}


sub unimport {
    shift;

    my %names;
    foreach (@_) {
	++$names{$_};
	++$names{"$_/$archname"} if -d "$_/$archname/auto";
    }

    # Remove ALL instances of each named directory.
    @INC = grep { !exists $names{$_} } @INC;
    return;
}

1;
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

=head2 Adding directories to @INC

The parameters to C<use lib> are added to the start of the perl search
path. Saying

    use lib LIST;

is I<almost> the same as saying

    BEGIN { unshift(@INC, LIST) }

For each directory in LIST (called $dir here) the lib module also
checks to see if a directory called $dir/$archname/auto exists.
If so the $dir/$archname directory is assumed to be a corresponding
architecture specific directory and is added to @INC in front of $dir.

To avoid memory leaks, all trailing duplicate entries in @INC are
removed.

=head2 Deleting directories from @INC

You should normally only add directories to @INC.  If you need to
delete directories from @INC take care to only delete those which you
added yourself or which you are certain are not needed by other modules
in your script.  Other modules may have added directories which they
need for correct operation.

The C<no lib> statement deletes all instances of each named directory
from @INC.

For each directory in LIST (called $dir here) the lib module also
checks to see if a directory called $dir/$archname/auto exists.
If so the $dir/$archname directory is assumed to be a corresponding
architecture specific directory and is also deleted from @INC.

=head2 Restoring original @INC

When the lib module is first loaded it records the current value of @INC
in an array C<@lib::ORIG_INC>. To restore @INC to that value you
can say

    @INC = @lib::ORIG_INC;


=head1 SEE ALSO

FindBin - optional module which deals with paths relative to the source file.

=head1 AUTHOR

Tim Bunce, 2nd June 1995.

=cut
