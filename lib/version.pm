#!perl -w
package version;

use 5.005_03;
use strict;

require DynaLoader;
use vars qw(@ISA $VERSION $CLASS);

@ISA = qw(DynaLoader);

$VERSION = 0.29; # stop using CVS and switch to subversion

$CLASS = 'version';

local $^W; # shut up the 'redefined' warning for UNIVERSAL::VERSION
bootstrap version if $] < 5.009;

# Preloaded methods go here.

1;
__END__

=head1 NAME

version - Perl extension for Version Objects

=head1 SYNOPSIS

  use version;
  $version = new version "12.2.1"; # must be quoted!
  print $version; 		# 12.2.1
  print $version->numify; 	# 12.002001
  if ( $version gt  "v12.2" )	# true

  $vstring = new version qw(v1.2); # must be quoted!
  print $vstring;		# 1.2

  $alphaver = new version "1.2_3"; # must be quoted!
  print $alphaver;		# 1.2_3
  print $alphaver->is_alpha();  # true

  $perlver = new version 5.005_03; # must not be quoted!
  print $perlver;		# 5.5.30

=head1 DESCRIPTION

Overloaded version objects for all versions of Perl.  This module
implements all of the features of version objects which will be part
of Perl 5.10.0 except automatic v-string handling.  See L<"Quoting">.

=head2 What IS a version

For the purposes of this module, a version "number" is a sequence of
positive integral values separated by decimal points and optionally a
single underscore.  This corresponds to what Perl itself uses for a
version, as well as extending the "version as number" that is discussed
in the various editions of the Camel book.

There are actually two distinct ways to initialize versions:

=over 4

=item * Numeric Versions

Any initial parameter which "looks like a number", see L<Numeric
Versions>.

=item * V-String Versions

Any initial parameter which contains more than one decimal point,
contains an embedded underscore, or has a leading 'v' see L<V-String
Versions>.

=back

Both of these methods will produce similar version objects, in that
the default stringification will always be in a reduced form, i.e.:

  $v  = new version 1.002003;  # 1.2.3
  $v2 = new version  "1.2.3";  # 1.2.3
  $v3 = new version   v1.2.3;  # 1.2.3 for Perl > v5.8.0
  $v4 = new version    1.2.3;  # 1.2.3 for Perl > v5.8.0

Please see L<"Quoting"> for more details on how Perl will parse various
input values.

Any value passed to the new() operator will be parsed only so far as it
contains a numeric, decimal, or underscore character.  So, for example:

  $v1 = new version "99 and 94/100 percent pure"; # $v1 == 99.0
  $v2 = new version "something"; # $v2 == "" and $v2->numify == 0

However, see L<New Operator> for one case where non-numeric text is
acceptable when initializing version objects.

=head2 Numeric Versions

These correspond to historical versions of Perl itself prior to v5.6.0,
as well as all other modules which follow the Camel rules for the
$VERSION scalar.  A numeric version is initialized with what looks like
a floating point number.  Leading zeros B<are> significant and trailing
zeros are implied so that a minimum of three places is maintained
between subversions.  What this means is that any subversion (digits
to the right of the decimal place) that contains less than three digits
will have trailing zeros added to make up the difference.  For example:

  $v = new version       1.2;    # 1.200
  $v = new version      1.02;    # 1.20
  $v = new version     1.002;    # 1.2
  $v = new version    1.0023;    # 1.2.300
  $v = new version   1.00203;    # 1.2.30
  $v = new version  1.002_03;    # 1.2.30   See L<"Quoting">
  $v = new version  1.002003;    # 1.2.3

All of the preceeding examples except the second to last are true
whether or not the input value is quoted.  The important feature is that
the input value contains only a single decimal.

=head2 V-String Versions

These are the newest form of versions, and correspond to Perl's own
version style beginning with v5.6.0.  Starting with Perl v5.10.0,
this is likely to be the preferred form.  This method requires that
the input parameter be quoted, although Perl > v5.9.0 can use bare
v-strings as a special form of quoting.

Unlike L<Numeric Versions>, V-String Versions must either have more than
a single decimal point, e.g. "5.6.1" B<or> must be prefaced by a "v"
like this "v5.6" (much like v-string notation).  In fact, with the
newest Perl v-strings themselves can be used to initialize version
objects.  Also unlike L<Numeric Versions>, leading zeros are B<not>
significant, and trailing zeros must be explicitely specified (i.e.
will not be automatically added).  In addition, the subversions are
not enforced to be three decimal places.

So, for example:

  $v = new version    "v1.2";    # 1.2
  $v = new version  "v1.002";    # 1.2
  $v = new version   "1.2.3";    # 1.2.3
  $v = new version  "v1.2.3";    # 1.2.3
  $v = new version "v1.0003";    # 1.3

In additional to conventional versions, V-String Versions can be
used to create L<Alpha Versions>.

In general, V-String Versions permit the greatest amount of freedom
to specify a version, whereas Numeric Versions enforce a certain
uniformity.  See also L<New Operator> for an additional method of
initializing version objects.

=head2 Object Methods

Overloading has been used with version objects to provide a natural
interface for their use.  All mathematical operations are forbidden,
since they don't make any sense for base version objects.

=over 4

=item * New Operator

Like all OO interfaces, the new() operator is used to initialize
version objects.  One way to increment versions when programming is to
use the CVS variable $Revision, which is automatically incremented by
CVS every time the file is committed to the repository.

=back

In order to facilitate this feature, the following
code can be employed:

  $VERSION = new version qw$Revision: 2.7 $;

and the version object will be created as if the following code
were used:

  $VERSION = new version "v2.7";

In other words, the version will be automatically parsed out of the
string, and it will be quoted to preserve the meaning CVS normally
carries for versions.

For the subsequent examples, the following two objects will be used:

  $ver  = new version "1.2.3"; # see "Quoting" below
  $alpha = new version "1.2_3"; # see "Alpha versions" below

=over 4

=item * Stringification

Any time a version object is used as a string, a stringified
representation is returned in reduced form (no extraneous zeros):

=back

  print $ver->stringify;      # prints 1.2.3
  print $ver;                 # same thing

=over 4

=item * Numification

Although all mathematical operations on version objects are forbidden
by default, it is possible to retrieve a number which roughly
corresponds to the version object through the use of the $obj->numify
method.  For formatting purposes, when displaying a number which
corresponds a version object, all sub versions are assumed to have
three decimal places.  So for example:

  print $ver->numify;         # prints 1.002003

=item * Comparison operators

Both cmp and <=> operators perform the same comparison between terms
(upgrading to a version object automatically).  Perl automatically
generates all of the other comparison operators based on those two.
In addition to the obvious equalities listed below, appending a single
trailing 0 term does not change the value of a version for comparison
purposes.  In other words "v1.2" and "v1.2.0" are identical versions.

For example, the following relations hold:

  As Number       As String          Truth Value
  ---------       ------------       -----------
  $ver >  1.0     $ver gt "1.0"      true
  $ver <  2.5     $ver lt            true
  $ver != 1.3     $ver ne "1.3"      true
  $ver == 1.2     $ver eq "1.2"      false
  $ver == 1.2.3   $ver eq "1.2.3"    see discussion below
  $ver == v1.2.3  $ver eq "v1.2.3"   ditto

In versions of Perl prior to the 5.9.0 development releases, it is not
permitted to use bare v-strings in either form, due to the nature of Perl's
parsing operation.  After that version (and in the stable 5.10.0 release),
v-strings can be used with version objects without problem, see L<"Quoting">
for more discussion of this topic.  In the case of the last two lines of
the table above, only the string comparison will be true; the numerical
comparison will test false.  However, you can do this:

  $ver == "1.2.3" or $ver == "v1.2.3"	# both true

even though you are doing a "numeric" comparison with a "string" value.
It is probably best to chose either the numeric notation or the string
notation and stick with it, to reduce confusion.  See also L<"Quoting">.

=item * Logical Operators 

If you need to test whether a version object
has been initialized, you can simply test it directly:

  $vobj = new version $something;
  if ( $vobj )   # true only if $something was non-blank

You can also test whether a version object is a L<Alpha version>, for
example to prevent the use of some feature not present in the main
release:

  $vobj = new version "1.2_3"; # MUST QUOTE
  ...later...
  if ( $vobj->is_alpha )       # True

=back

=head2 Quoting

Because of the nature of the Perl parsing and tokenizing routines,
certain initialization values B<must> be quoted in order to correctly
parse as the intended version, and additionally, some initial values
B<must not> be quoted to obtain the intended version.

Except for L<Alpha versions>, any version initialized with something
that looks like a number (a single decimal place) will be parsed in
the same way whether or not the term is quoted.  In order to be
compatible with earlier Perl version styles, any use of versions of
the form 5.006001 will be translated as 5.6.1.  In other words, a
version with a single decimal place will be parsed as implicitly
having three places between subversions.

The complicating factor is that in bare numbers (i.e. unquoted), the
underscore is a legal numeric character and is automatically stripped
by the Perl tokenizer before the version code is called.  However, if
a number containing a single decimal and an underscore is quoted, i.e.
not bare, that is considered a L<Alpha Version> and the underscore is
significant.

If you use a mathematic formula that resolves to a floating point number,
you are dependent on Perl's conversion routines to yield the version you
expect.  You are pretty safe by dividing by a power of 10, for example,
but other operations are not likely to be what you intend.  For example:

  $VERSION = new version (qw$Revision: 1.4)[1]/10;
  print $VERSION;          # yields 0.14
  $V2 = new version 100/9; # Integer overflow in decimal number
  print $V2;               # yields 11_1285418553

Perl 5.9.0 and beyond will be able to automatically quote v-strings
(which may become the recommended notation), but that is not possible in
earlier versions of Perl.  In other words:

  $version = new version "v2.5.4";  # legal in all versions of Perl
  $newvers = new version v2.5.4;    # legal only in Perl > 5.9.0


=head2 Types of Versions Objects

There are two types of Version Objects:

=over 4

=item * Ordinary versions

These are the versions that normal modules will use.  Can contain as
many subversions as required.  In particular, those using RCS/CVS can
use one of the following:

  $VERSION = new version qw$Revision: 2.7 $;

and the current RCS Revision for that file will be inserted
automatically.  If the file has been moved to a branch, the Revision
will have three or more elements; otherwise, it will have only two.
This allows you to automatically increment your module version by
using the Revision number from the primary file in a distribution, see
L<ExtUtils::MakeMaker/"VERSION_FROM">.

=item * alpha versions

For module authors using CPAN, the convention has been to note
unstable releases with an underscore in the version string, see
L<CPAN>.  Alpha releases will test as being newer than the more recent
stable release, and less than the next stable release.  For example:

  $alphaver = new version "12.3_1"; # must quote

obeys the relationship

  12.3 < $alphaver < 12.4

As a matter of fact, if is also true that

  12.3.0 < $alphaver < 12.3.1

where the subversion is identical but the alpha release is less than
the non-alpha release.

=head2 Replacement UNIVERSAL::VERSION

In addition to the version objects, this modules also replaces the core
UNIVERSAL::VERSION function with one that uses version objects for its
comparisons.

=head1 EXPORT

None by default.

=head1 AUTHOR

John Peacock E<lt>jpeacock@rowman.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
