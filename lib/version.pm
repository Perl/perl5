#!/usr/local/bin/perl -w
package version;

use 5.005_03;
use strict;

require DynaLoader;
use vars qw(@ISA $VERSION $CLASS);

@ISA = qw(DynaLoader);

$VERSION = (qw$Revision: 2.1 $)[1]/10;

$CLASS = 'version';

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
  if ( $version > 12.2 )	# true

  $vstring = new version qw(v1.2); # must be quoted!
  print $vstring;		# 1.2

  $betaver = new version "1.2_3"; # must be quoted!
  print $betaver;		# 1.2_3

  $perlver = new version "5.005_03"; # must be quoted!
  print $perlver;		# 5.5.30

=head1 DESCRIPTION

Overloaded version objects for all versions of Perl.  This module
implments all of the features of version objects which will be part
of Perl 5.10.0 except automatic v-string handling.  See L<"Quoting">.

=head2 What IS a version

For the purposes of this module, a version "number" is a sequence of
positive integral values separated by decimal points and optionally a
single underscore.  This corresponds to what Perl itself uses for a
version, as well as extending the "version as number" that is discussed
in the various editions of the Camel book.

=head2 Object Methods

Overloading has been used with version objects to provide a natural
interface for their use.  All mathematical operations are forbidden,
since they don't make any sense for versions.  For the subsequent
examples, the following two objects will be used:

  $ver  = new version "1.2.3"; # see "Quoting" below
  $beta = new version "1.2_3"; # see "Beta versions" below

=item * Stringification - Any time a version object is used as a string,
a stringified representation is returned in reduced form (no extraneous
zeros): 

  print $ver->stringify;      # prints 1.2.3
  print $ver;                 # same thing

=item * Numification - although all mathematical operations on version
objects are forbidden by default, it is possible to retrieve a number
which roughly corresponds to the version object through the use of the
$obj->numify method.  For formatting purposes, when displaying a number
which corresponds a version object, all sub versions are assumed to have
three decimal places.  So for example:

  print $ver->numify;         # prints 1.002003

=item * Comparison operators - Both cmp and <=> operators perform the
same comparison between terms (upgrading to a version object
automatically).  Perl automatically generates all of the other comparison
operators based on those two.  For example, the following relations hold:

  As Number       As String       Truth Value
  ---------       ------------    -----------
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

  $ver == "1.2.3" or $ver = "v.1.2.3"	# both true

even though you are doing a "numeric" comparison with a "string" value.
It is probably best to chose either the numeric notation or the string 
notation and stick with it, to reduce confusion.  See also L<"Quoting">.

=head2 Quoting

Because of the nature of the Perl parsing and tokenizing routines, 
you should always quote the parameter to the new() operator/method.  The
exact notation is vitally important to correctly determine the version
that is requested.  You don't B<have> to quote the version parameter,
but you should be aware of what Perl is likely to do in those cases.

If you use a mathematic formula that resolves to a floating point number,
you are dependent on Perl's conversion routines to yield the version you
expect.  You are pretty safe by dividing by a power of 10, for example,
but other operations are not likely to be what you intend.  For example:

  $VERSION = new version (qw$Revision: 1.4)[1]/10;
  print $VERSION;          # yields 0.14
  $V2 = new version 100/9; # Integer overflow in decimal number
  print $V2;               # yields 11_1285418553

You B<can> use a bare number, if you only have a major and minor version,
since this should never in practice yield a floating point notation
error.  For example:

  $VERSION = new version  10.2;  # almost certainly ok
  $VERSION = new version "10.2"; # guaranteed ok

Perl 5.9.0 and beyond will be able to automatically quote v-strings
(which may become the recommended notation), but that is not possible in
earlier versions of Perl.  In other words:

  $version = new version "v2.5.4";  # legal in all versions of Perl
  $newvers = new version v2.5.4;    # legal only in Perl > 5.9.0


=head2 Types of Versions Objects

There are three basic types of Version Objects:

=item * Ordinary versions - These are the versions that normal
modules will use.  Can contain as many subversions as required.
In particular, those using RCS/CVS can use one of the following:

  $VERSION = new version (qw$Revision: 2.1 $)[1]; # all Perls
  $VERSION = new version qw$Revision: 2.1 $[1];   # Perl >= 5.6.0

and the current RCS Revision for that file will be inserted 
automatically.  If the file has been moved to a branch, the
Revision will have three or more elements; otherwise, it will
have only two.  This allows you to automatically increment
your module version by using the Revision number from the primary
file in a distribution, see L<ExtUtils::MakeMaker/"VERSION_FROM">.

In order to be compatible with earlier Perl version styles, any use
of versions of the form 5.006001 will be translated as 5.6.1,  In 
other words a version with a single decimal place will be parsed
as implicitely having three places between subversion.

=item * Beta versions - For module authors using CPAN, the 
convention has been to note unstable releases with an underscore
in the version string, see L<CPAN>.  Beta releases will test as being
newer than the more recent stable release, and less than the next
stable release.  For example:

  $betaver = new version "12.3_1"; # must quote

obeys the relationship

  12.3 < $betaver < 12.4

As a matter of fact, if is also true that

  12.3.0 < $betaver < 12.3.1

where the subversion is identical but the beta release is less than
the non-beta release.

=item * Perl-style versions - an exceptional case is versions that
were only used by Perl releases prior to 5.6.0.  If a version
string contains an underscore immediately followed by a zero followed
by a non-zero number, the version is processed according to the rules
described in L<perldelta/Improved Perl version numbering system>
released with Perl 5.6.0.  As an example:

  $perlver = new version "5.005_03";

is interpreted, not as a beta release, but as the version 5.5.30,  NOTE
that the major and minor versions are unchanged but the subversion is
multiplied by 10, since the above was implicitely read as 5.005.030.
There are modules currently on CPAN which may fall under of this rule, so
module authors are urged to pay close attention to what version they are
specifying.

=head2 Replacement UNIVERSAL::VERSION

In addition to the version objects, this modules also replaces the core
UNIVERSAL::VERSION function with one that uses version objects for its
comparisons.  So, for example, with all existing versions of Perl,
something like the following pseudocode would fail:

	package vertest;
	$VERSION = 0.45;

	package main;
	use vertest 0.5;

even though those versions are meant to be read as 0.045 and 0.005 
respectively.  The UNIVERSAL::VERSION replacement function included
with this module changes that behavior so that it will B<not> fail.

=head1 EXPORT

None by default.

=head1 AUTHOR

John Peacock E<lt>jpeacock@rowman.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
#!/usr/local/bin/perl -w
package version;

use 5.005_03;
use strict;

require Exporter;
require DynaLoader;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION $CLASS);

@ISA = qw(Exporter DynaLoader);

# This allows declaration	use version ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(

) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
);

$VERSION = (qw$Revision: 1.8 $)[1]/10;

$CLASS = 'version';

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
  if ( $version > 12.2 )	# true

  $vstring = new version qw(v1.2); # must be quoted!
  print $vstring;		# 1.2

  $betaver = new version "1.2_3"; # must be quoted!
  print $betaver;		# 1.2_3

  $perlver = new version "5.005_03"; # must be quoted!
  print $perlver;		# 5.5.30

=head1 DESCRIPTION

Overloaded version objects for all versions of Perl.  This module
implments all of the features of version objects which will be part
of Perl 5.10.0 except automatic v-string handling.  See L<"Quoting">.

=head2 What IS a version

For the purposes of this module, a version "number" is a sequence of
positive integral values separated by decimal points and optionally a
single underscore.  This corresponds to what Perl itself uses for a
version, as well as including the "version as number" that is discussed
in the various editions of the Camel book.

=head2 Object Methods

Overloading has been used with version objects to provide a natural
interface for their use.  All mathematical operations are forbidden,
since they don't make any sense for versions.  For the subsequent
examples, the following two objects will be used:

  $ver  = new version "1.2.3"; # see "Quoting" below
  $beta = new version "1.2_3"; # see "Beta versions" below

=item * Stringification - Any time a version object is used as a string,
a stringified representation is returned in reduced form (no extraneous
zeros): 

  print $ver->stringify;      # prints 1.2.3
  print $ver;                 # same thing

=item * Numification - although all mathematical operations on version
objects are forbidden by default, it is possible to retrieve a number
which roughly corresponds to the version object through the use of the
$obj->numify method.  For formatting purposes, when displaying a number
which corresponds a version object, all sub versions are assumed to have
three decimal places.  So for example:

  print $ver->numify;         # prints 1.002003

=item * Comparison operators - Both cmp and <=> operators perform the
same comparison between terms (upgrading to a version object
automatically).  Perl automatically generates all of the other comparison
operators based on those two.  For example, the following relations hold:

  As Number       As String       Truth Value
  ---------       ------------    -----------
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

  $ver == "1.2.3" or $ver = "v.1.2.3"	# both true

even though you are doing a "numeric" comparison with a "string" value.
It is probably best to chose either the numeric notation or the string 
notation and stick with it, to reduce confusion.  See also L<"Quoting">.

=head2 Quoting

Because of the nature of the Perl parsing and tokenizing routines, 
you should always quote the parameter to the new() operator/method.  The
exact notation is vitally important to correctly determine the version
that is requested.  You don't B<have> to quote the version parameter,
but you should be aware of what Perl is likely to do in those cases.

If you use a mathematic formula that resolves to a floating point number,
you are dependent on Perl's conversion routines to yield the version you
expect.  You are pretty safe by dividing by a power of 10, for example,
but other operations are not likely to be what you intend.  For example:

  $VERSION = new version (qw$Revision: 1.4)[1]/10;
  print $VERSION;          # yields 0.14
  $V2 = new version 100/9; # Integer overflow in decimal number
  print $V2;               # yields 11_1285418553

You B<can> use a bare number, if you only have a major and minor version,
since this should never in practice yield a floating point notation
error.  For example:

  $VERSION = new version  10.2;  # almost certainly ok
  $VERSION = new version "10.2"; # guaranteed ok

Perl 5.9.0 and beyond will be able to automatically quote v-strings
(which may become the recommended notation), but that is not possible in
earlier versions of Perl.  In other words:

  $version = new version "v2.5.4";  # legal in all versions of Perl
  $newvers = new version v2.5.4;    # legal only in Perl > 5.9.0


=head2 Types of Versions Objects

There are three basic types of Version Objects:

=item * Ordinary versions - These are the versions that normal
modules will use.  Can contain as many subversions as required.
In particular, those using RCS/CVS can use one of the following:

  $VERSION = new version (qw$Revision: 1.8 $)[1]; # all Perls
  $VERSION = new version qw$Revision: 1.8 $[1];   # Perl >= 5.6.0

and the current RCS Revision for that file will be inserted 
automatically.  If the file has been moved to a branch, the
Revision will have three or more elements; otherwise, it will
have only two.  This allows you to automatically increment
your module version by using the Revision number from the primary
file in a distribution, see L<ExtUtils::MakeMaker/"VERSION_FROM">.

=item * Beta versions - For module authors using CPAN, the 
convention has been to note unstable releases with an underscore
in the version string, see L<CPAN>.  Beta releases will test as being
newer than the more recent stable release, and less than the next
stable release.  For example:

  $betaver = new version "12.3_1"; # must quote

obeys the relationship

  12.3 < $betaver < 12.4

As a matter of fact, if is also true that

  12.3.0 < $betaver < 12.3.1

where the subversion is identical but the beta release is less than
the non-beta release.

=item * Perl-style versions - an exceptional case is versions that
were only used by Perl releases prior to 5.6.0.  If a version
string contains an underscore immediately followed by a zero followed
by a non-zero number, the version is processed according to the rules
described in L<perldelta/Improved Perl version numbering system>
released with Perl 5.6.0.  As an example:

  $perlver = new version "5.005_03";

is interpreted, not as a beta release, but as the version 5.5.30,  NOTE
that the major and minor versions are unchanged but the subversion is
multiplied by 10, since the above was implicitely read as 5.005.030.
There are modules currently on CPAN which may fall under of this rule, so
module authors are urged to pay close attention to what version they are
specifying.

=head2 Replacement UNIVERSAL::VERSION

In addition to the version objects, this modules also replaces the core
UNIVERSAL::VERSION function with one that uses version objects for its
comparisons.  So, for example, with all existing versions of Perl,
something like the following pseudocode would fail:

	package vertest;
	$VERSION = 0.45;

	package main;
	use vertest 0.5;

even though those versions are meant to be read as 0.045 and 0.005 
respectively.  The UNIVERSAL::VERSION replacement function included
with this module changes that behavior so that it will B<not> fail.

=head1 EXPORT

None by default.

=head1 AUTHOR

John Peacock E<lt>jpeacock@rowman.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
