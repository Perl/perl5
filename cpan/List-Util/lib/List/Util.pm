# List::Util.pm
#
# Copyright (c) 1997-2009 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This module is normally only loaded if the XS module is not available

package List::Util;

use strict;
require Exporter;

our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw(first min max minstr maxstr reduce sum sum0 shuffle pairmap pairgrep pairfirst pairs pairkeys pairvalues);
our $VERSION    = "1.31";
our $XS_VERSION = $VERSION;
$VERSION    = eval $VERSION;

require XSLoader;
XSLoader::load('List::Util', $XS_VERSION);

sub sum0
{
   return 0 unless @_;
   goto &sum;
}

1;

__END__

=head1 NAME

List::Util - A selection of general-utility list subroutines

=head1 SYNOPSIS

    use List::Util qw(first max maxstr min minstr reduce shuffle sum);

=head1 DESCRIPTION

C<List::Util> contains a selection of subroutines that people have
expressed would be nice to have in the perl core, but the usage would
not really be high enough to warrant the use of a keyword, and the size
so small such that being individual extensions would be wasteful.

By default C<List::Util> does not export any subroutines.

=cut

=head1 LIST-REDUCTION FUNCTIONS

The following set of functions all reduce a list down to a single value.

=cut

=head2 reduce BLOCK LIST

Reduces LIST by calling BLOCK, in a scalar context, multiple times,
setting C<$a> and C<$b> each time. The first call will be with C<$a>
and C<$b> set to the first two elements of the list, subsequent
calls will be done by setting C<$a> to the result of the previous
call and C<$b> to the next element in the list.

Returns the result of the last call to BLOCK. If LIST is empty then
C<undef> is returned. If LIST only contains one element then that
element is returned and BLOCK is not executed.

    $foo = reduce { $a < $b ? $a : $b } 1..10       # min
    $foo = reduce { $a lt $b ? $a : $b } 'aa'..'zz' # minstr
    $foo = reduce { $a + $b } 1 .. 10               # sum
    $foo = reduce { $a . $b } @bar                  # concat

If your algorithm requires that C<reduce> produce an identity value, then
make sure that you always pass that identity value as the first argument to prevent
C<undef> being returned

  $foo = reduce { $a + $b } 0, @values;             # sum with 0 identity value

The remaining list-reduction functions are all specialisations of this
generic idea.

=head2 first BLOCK LIST

Similar to C<grep> in that it evaluates BLOCK setting C<$_> to each element
of LIST in turn. C<first> returns the first element where the result from
BLOCK is a true value. If BLOCK never returns true or LIST was empty then
C<undef> is returned.

    $foo = first { defined($_) } @list    # first defined value in @list
    $foo = first { $_ > $value } @list    # first value in @list which
                                          # is greater than $value

This function could be implemented using C<reduce> like this

    $foo = reduce { defined($a) ? $a : wanted($b) ? $b : undef } undef, @list

for example wanted() could be defined() which would return the first
defined value in @list

=head2 max LIST

Returns the entry in the list with the highest numerical value. If the
list is empty then C<undef> is returned.

    $foo = max 1..10                # 10
    $foo = max 3,9,12               # 12
    $foo = max @bar, @baz           # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a > $b ? $a : $b } 1..10

=head2 maxstr LIST

Similar to C<max>, but treats all the entries in the list as strings
and returns the highest string as defined by the C<gt> operator.
If the list is empty then C<undef> is returned.

    $foo = maxstr 'A'..'Z'          # 'Z'
    $foo = maxstr "hello","world"   # "world"
    $foo = maxstr @bar, @baz        # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a gt $b ? $a : $b } 'A'..'Z'

=head2 min LIST

Similar to C<max> but returns the entry in the list with the lowest
numerical value. If the list is empty then C<undef> is returned.

    $foo = min 1..10                # 1
    $foo = min 3,9,12               # 3
    $foo = min @bar, @baz           # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a < $b ? $a : $b } 1..10

=head2 minstr LIST

Similar to C<min>, but treats all the entries in the list as strings
and returns the lowest string as defined by the C<lt> operator.
If the list is empty then C<undef> is returned.

    $foo = minstr 'A'..'Z'          # 'A'
    $foo = minstr "hello","world"   # "hello"
    $foo = minstr @bar, @baz        # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a lt $b ? $a : $b } 'A'..'Z'

=head2 sum LIST

Returns the sum of all the elements in LIST. If LIST is empty then
C<undef> is returned.

    $foo = sum 1..10                # 55
    $foo = sum 3,9,12               # 24
    $foo = sum @bar, @baz           # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a + $b } 1..10

=head2 sum0 LIST

Similar to C<sum>, except this returns 0 when given an empty list, rather
than C<undef>.

=cut

=head1 KEY/VALUE PAIR LIST FUNCTIONS

The following set of functions, all inspired by L<List::Pairwise>, consume
an even-sized list of pairs. The pairs may be key/value associations from a
hash, or just a list of values. The functions will all preserve the original
ordering of the pairs, and will not be confused by multiple pairs having the
same "key" value - nor even do they require that the first of each pair be a
plain string.

=cut

=head2 pairgrep BLOCK KVLIST

Similar to perl's C<grep> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the BLOCK multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
KVLIST.

Returns an even-sized list of those pairs for which the BLOCK returned true
in list context, or the count of the B<number of pairs> in scalar context.
(Note, therefore, in scalar context that it returns a number half the size
of the count of items it would have returned in list context).

    @subset = pairgrep { $a =~ m/^[[:upper:]]+$/ } @kvlist

Similar to C<grep>, C<pairgrep> aliases C<$a> and C<$b> to elements of the
given list. Any modifications of it by the code block will be visible to
the caller.

=head2 pairfirst BLOCK KVLIST

Similar to the C<first> function, but interprets the given list as an
even-sized list of pairs. It invokes the BLOCK multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
KVLIST.

Returns the first pair of values from the list for which the BLOCK returned
true in list context, or an empty list of no such pair was found. In scalar
context it returns a simple boolean value, rather than either the key or the
value found.

    ( $key, $value ) = pairfirst { $a =~ m/^[[:upper:]]+$/ } @kvlist

Similar to C<grep>, C<pairfirst> aliases C<$a> and C<$b> to elements of the
given list. Any modifications of it by the code block will be visible to
the caller.

=head2 pairmap BLOCK KVLIST

Similar to perl's C<map> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the BLOCK multiple times, in list
context, with C<$a> and C<$b> set to successive pairs of values from the
KVLIST.

Returns the concatenation of all the values returned by the BLOCK in list
context, or the count of the number of items that would have been returned
in scalar context.

    @result = pairmap { "The key $a has value $b" } @kvlist

Similar to C<map>, C<pairmap> aliases C<$a> and C<$b> to elements of the
given list. Any modifications of it by the code block will be visible to
the caller.

=head2 pairs KVLIST

A convenient shortcut to operating on even-sized lists of pairs, this
function returns a list of ARRAY references, each containing two items from
the given list. It is a more efficient version of

    pairmap { [ $a, $b ] } KVLIST

It is most convenient to use in a C<foreach> loop, for example:

    foreach ( pairs @KVLIST ) {
       my ( $key, $value ) = @$_;
       ...
    }

=head2 pairkeys KVLIST

A convenient shortcut to operating on even-sized lists of pairs, this
function returns a list of the the first values of each of the pairs in
the given list. It is a more efficient version of

    pairmap { $a } KVLIST

=head2 pairvalues KVLIST

A convenient shortcut to operating on even-sized lists of pairs, this
function returns a list of the the second values of each of the pairs in
the given list. It is a more efficient version of

    pairmap { $b } KVLIST

=cut

=head1 OTHER FUNCTIONS

=cut

=head2 shuffle LIST

Returns the elements of LIST in a random order

    @cards = shuffle 0..51      # 0..51 in a random order

=cut

=head1 KNOWN BUGS

With perl versions prior to 5.005 there are some cases where reduce
will return an incorrect result. This will show up as test 7 of
reduce.t failing.

=head1 SUGGESTED ADDITIONS

The following are additions that have been requested, but I have been reluctant
to add due to them being very simple to implement in perl

  # One argument is true

  sub any { $_ && return 1 for @_; 0 }

  # All arguments are true

  sub all { $_ || return 0 for @_; 1 }

  # All arguments are false

  sub none { $_ && return 0 for @_; 1 }

  # One argument is false

  sub notall { $_ || return 1 for @_; 0 }

  # How many elements are true

  sub true { scalar grep { $_ } @_ }

  # How many elements are false

  sub false { scalar grep { !$_ } @_ }

=head1 SEE ALSO

L<Scalar::Util>, L<List::MoreUtils>

=head1 COPYRIGHT

Copyright (c) 1997-2007 Graham Barr <gbarr@pobox.com>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Recent additions and current maintenance by
Paul Evans, <leonerd@leonerd.org.uk>.

=cut
