#!perl -w
package version;

use 5.005_03;
use strict;

require Exporter;
require DynaLoader;
use vars qw(@ISA $VERSION $CLASS @EXPORT);

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(qv);

$VERSION = 0.37; # stop using CVS and switch to subversion

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
  $version = version->new("12.2.1"); # must be quoted for Perl < 5.8.1
  print $version; 		# 12.2.1
  print $version->numify; 	# 12.002001
  if ( $version gt  "12.2" )	# true

  $alphaver = version->new("1.2_3"); # must be quoted!
  print $alphaver;		# 1.2_3
  print $alphaver->is_alpha();  # true
  
  $ver = qv(1.2);               # 1.2.0
  $ver = qv("1.2");             # 1.2.0

  $perlver = version->new(5.005_03); # must not be quoted!
  print $perlver;		# 5.5.30

=head1 DESCRIPTION

Overloaded version objects for all versions of Perl.  This module
implements all of the features of version objects which will be part
of Perl 5.10.0 except automatic version object creation.

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

=item * Quoted Versions

Any initial parameter which contains more than one decimal point
or contains an embedded underscore, see L<Quoted Versions>.  The
most recent development version of Perl (5.9.x) and the next major
release (5.10.0) will automatically create version objects for bare
numbers containing more than one decimal point in the appropriate
context.

=back

Both of these methods will produce similar version objects, in that
the default stringification will yield the version L<Normal Form> only 
if required:

  $v  = version->new(1.002);     # 1.002, but compares like 1.2.0
  $v  = version->new(1.002003);  # 1.2.3
  $v2 = version->new( "1.2.3");  # 1.2.3
  $v3 = version->new(  1.2.3);   # 1.2.3 for Perl >= 5.8.1

Please see L<"Quoting"> for more details on how Perl will parse various
input values.

Any value passed to the new() operator will be parsed only so far as it
contains a numeric, decimal, or underscore character.  So, for example:

  $v1 = version->new("99 and 94/100 percent pure"); # $v1 == 99.0
  $v2 = version->new("something"); # $v2 == "" and $v2->numify == 0

However, see L<New Operator> for one case where non-numeric text is
acceptable when initializing version objects.

=head2 What about v-strings?

Beginning with Perl 5.6.0, an alternate method to code arbitrary strings
of bytes was introduced, called v-strings.  They were intended to be an
easy way to enter, for example, Unicode strings (which contain two bytes
per character).  Some programs have used them to encode printer control
characters (e.g. CRLF).  They were also intended to be used for $VERSION.
Their use has been problematic from the start and they will be phased out
beginning in Perl 5.10.0.

There are two ways to enter v-strings: a bare number with two or more
decimal places, or a bare number with one or more decimal places and a 
leading 'v' character (also bare).  For example:

  $vs1 = 1.2.3; # encoded as \1\2\3
  $vs2 = v1.2;  # encoded as \1\2 

The first of those two syntaxes is destined to be the default way to create
a version object in 5.10.0, whereas the second will issue a mandatory
deprecation warning beginning at the same time.  In both cases, a v-string
encoded version will always be stringified in the version L<Normal Form>.

Consequently, the use of v-strings to initialize version objects with
this module is only possible with Perl 5.8.1 or better (which contain special
code to enable it).  Their use is B<strongly> discouraged in all 
circumstances (especially the leading 'v' style), since the meaning will
change depending on which Perl you are running.  It is better to use
L<"Quoted Versions"> to ensure the proper interpretation.

=head2 Numeric Versions

These correspond to historical versions of Perl itself prior to 5.6.0,
as well as all other modules which follow the Camel rules for the
$VERSION scalar.  A numeric version is initialized with what looks like
a floating point number.  Leading zeros B<are> significant and trailing
zeros are implied so that a minimum of three places is maintained
between subversions.  What this means is that any subversion (digits
to the right of the decimal place) that contains less than three digits
will have trailing zeros added to make up the difference, but only for
purposes of comparison with other version objects.  For example:

  $v = version->new(      1.2);    # prints 1.2, compares as 1.200.0
  $v = version->new(     1.02);    # prints 1.02, compares as 1.20.0
  $v = version->new(    1.002);    # prints 1.002, compares as 1.2.0
  $v = version->new(   1.0023);    # 1.2.300
  $v = version->new(  1.00203);    # 1.2.30
  $v = version->new( 1.002_03);    # 1.2.30   See "Quoting"
  $v = version->new( 1.002003);    # 1.2.3

All of the preceeding examples except the second to last are true
whether or not the input value is quoted.  The important feature is that
the input value contains only a single decimal.

IMPORTANT NOTE: If your numeric version contains more than 3 significant
digits after the decimal place, it will be split on each multiple of 3, so
1.0003 becomes 1.0.300, due to the need to remain compatible with Perl's
own 5.005_03 == 5.5.30 interpretation.

=head2 Quoted Versions

These are the newest form of versions, and correspond to Perl's own
version style beginning with 5.6.0.  Starting with Perl 5.10.0,
and most likely Perl 6, this is likely to be the preferred form.  This
method requires that the input parameter be quoted, although Perl's after 
5.9.0 can use bare numbers with multiple decimal places as a special form
of quoting.

Unlike L<Numeric Versions>, Quoted Versions may have more than
a single decimal point, e.g. "5.6.1" (for all versions of Perl).  If a
Quoted Version has only one decimal place (and no embedded underscore),
it is interpreted exactly like a L<Numeric Version>.  

So, for example:

  $v = version->new( "1.002");    # 1.2
  $v = version->new( "1.2.3");    # 1.2.3
  $v = version->new("1.0003");    # 1.0.300

In addition to conventional versions, Quoted Versions can be
used to create L<Alpha Versions>.

In general, Quoted Versions permit the greatest amount of freedom
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

In order to facilitate this feature, the following
code can be employed:

  $VERSION = version->new(qw$Revision: 2.7 $);

and the version object will be created as if the following code
were used:

  $VERSION = version->new("v2.7");

In other words, the version will be automatically parsed out of the
string, and it will be quoted to preserve the meaning CVS normally
carries for versions.

=back

=over 4

=item * qv()

An alternate way to create a new version object is through the exported
qv() sub.  This is not strictly like other q? operators (like qq, qw),
in that the only delimiters supported are parentheses (or spaces).  It is
the best way to initialize a short version without triggering the floating
point interpretation.  For example:

  $v1 = qv(1.2);         # 1.2.0
  $v2 = qv("1.2");       # also 1.2.0

As you can see, either a bare number or a quoted string can be used, and
either will yield the same version number.

=back

For the subsequent examples, the following two objects will be used:

  $ver   = version->new("1.2.3"); # see "Quoting" below
  $alpha = version->new("1.2_3"); # see "Alpha versions" below
  $nver  = version->new(1.2);     # see "Numeric Versions" above

=over 4

=item * Normal Form

For any version object which is initialized with multiple decimal
places (either quoted or if possible v-string), or initialized using
the L<qv()> operator, the stringified representation is returned in
a normalized or reduced form (no extraneous zeros):

  print $ver->normal;         # prints as 1.2.3
  print $ver->stringify;      # ditto
  print $ver;                 # ditto
  print $nver->normal;        # prints as 1.2.0
  print $nver->stringify;     # prints as 1.2, see "Stringification" 

In order to preserve the meaning of the processed version, the 
normalized representation will always contain at least three sub terms.
In other words, the following is guaranteed to always be true:

  my $newver = version->new($ver->stringify);
  if ($newver eq $ver ) # always true
    {...}

=back

=over 4

=item * Numification

Although all mathematical operations on version objects are forbidden
by default, it is possible to retrieve a number which roughly
corresponds to the version object through the use of the $obj->numify
method.  For formatting purposes, when displaying a number which
corresponds a version object, all sub versions are assumed to have
three decimal places.  So for example:

  print $ver->numify;         # prints 1.002003
  print $nver->numify;        # prints 1.2

Unlike the stringification operator, there is never any need to append
trailing zeros to preserve the correct version value.

=back

=over 4

=item * Stringification

In order to mirror as much as possible the existing behavior of ordinary
$VERSION scalars, the stringification operation will display differently,
depending on whether the version was initialized as a L<Numeric Version>
or L<Quoted Version>.

What this means in practice is that if the normal CPAN and Camel rules are
followed ($VERSION is a floating point number with no more than 3 decimal
places), the stringified output will be exactly the same as the numified
output.  There will be no visible difference, although the internal 
representation will be different, and the L<Comparison operators> will 
function using the internal coding.

If a version object is initialized using a L<Quoted Version> form, or if
the number of significant decimal places exceed three, then the stringified
form will be the L<Normal Form>.  The $obj->normal operation can always be
used to produce the L<Normal Form>, even if the version was originally a
L<Numeric Version>.

  print $ver->stringify;    # prints 1.2.3
  print $nver->stringify;   # prints 1.2

=back

=over 4

=item * Comparison operators

Both cmp and <=> operators perform the same comparison between terms
(upgrading to a version object automatically).  Perl automatically
generates all of the other comparison operators based on those two.
In addition to the obvious equalities listed below, appending a single
trailing 0 term does not change the value of a version for comparison
purposes.  In other words "v1.2" and "1.2.0" will compare as identical.

For example, the following relations hold:

  As Number       As String          Truth Value
  ---------       ------------       -----------
  $ver >  1.0     $ver gt "1.0"      true
  $ver <  2.5     $ver lt            true
  $ver != 1.3     $ver ne "1.3"      true
  $ver == 1.2     $ver eq "1.2"      false
  $ver == 1.2.3   $ver eq "1.2.3"    see discussion below

It is probably best to chose either the numeric notation or the string
notation and stick with it, to reduce confusion.  Perl6 version objects
B<may> only support numeric comparisons.  See also L<"Quoting">.

WARNING: Comparing version with unequal numbers of decimal places (whether
explicitely or implicitely initialized), may yield unexpected results at
first glance.  For example, the following inequalities hold:

  version->new(0.96)     > version->new(0.95); # 0.960.0 > 0.950.0
  version->new("0.96.1") < version->new(0.95); # 0.096.1 < 0.950.0

For this reason, it is best to use either exclusively L<Numeric Versions> or
L<Quoted Versions> with multiple decimal places.

=back

=over 4

=item * Logical Operators 

If you need to test whether a version object
has been initialized, you can simply test it directly:

  $vobj = version->new($something);
  if ( $vobj )   # true only if $something was non-blank

You can also test whether a version object is an L<Alpha version>, for
example to prevent the use of some feature not present in the main
release:

  $vobj = version->new("1.2_3"); # MUST QUOTE
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

  $VERSION = version->new((qw$Revision: 1.4)[1]/10);
  print $VERSION;          # yields 0.14
  $V2 = version->new(100/9); # Integer overflow in decimal number
  print $V2;               # yields something like 11.111.111.100

Perl 5.8.1 and beyond will be able to automatically quote v-strings
(although a warning may be issued under 5.9.x and 5.10.0), but that
is not possible in earlier versions of Perl.  In other words:

  $version = version->new("v2.5.4");  # legal in all versions of Perl
  $newvers = version->new(v2.5.4);    # legal only in Perl >= 5.8.1


=head2 Types of Versions Objects

There are two types of Version Objects:

=over 4

=item * Ordinary versions

These are the versions that normal modules will use.  Can contain as
many subversions as required.  In particular, those using RCS/CVS can
use the following:

  $VERSION = version->new(qw$Revision: 2.7 $);

and the current RCS Revision for that file will be inserted
automatically.  If the file has been moved to a branch, the Revision
will have three or more elements; otherwise, it will have only two.
This allows you to automatically increment your module version by
using the Revision number from the primary file in a distribution, see
L<ExtUtils::MakeMaker/"VERSION_FROM">.

=item * Alpha versions

For module authors using CPAN, the convention has been to note
unstable releases with an underscore in the version string, see
L<CPAN>.  Alpha releases will test as being newer than the more recent
stable release, and less than the next stable release.  For example:

  $alphaver = version->new("12.3_1"); # must quote

obeys the relationship

  12.3 < $alphaver < 12.4

As a matter of fact, if is also true that

  12.3.0 < $alphaver < 12.3.1

where the subversion is identical but the alpha release is less than
the non-alpha release.

=head2 Replacement UNIVERSAL::VERSION

In addition to the version objects, this modules also replaces the core
UNIVERSAL::VERSION function with one that uses version objects for its
comparisons.  The return from this operator is always the numified form,
and the warning message generated includes both the numified and normal
forms (for clarity).

For example:

  package Foo;
  $VERSION = 1.2;

  package Bar;
  $VERSION = "1.3.5"; # works with all Perl's (since it is quoted)

  package main;
  use version;

  print $Foo::VERSION; # prints 1.2

  print $Bar::VERSION; # prints 1.003005

  eval "use CGI 10"; # some far future release
  print $@; # prints "CGI version 10 (10.0.0) required..."

IMPORTANT NOTE: This may mean that code which searches for a specific
string (to determine whether a given module is available) may need to be
changed.

=head1 EXPORT

qv - quoted version initialization operator

=head1 AUTHOR

John Peacock E<lt>jpeacock@rowman.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
