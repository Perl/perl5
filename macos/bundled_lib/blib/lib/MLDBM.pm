#
# MLDBM.pm
#
# store multi-level hash structure in single level tied hash (read DBM)
#
# Documentation at the __END__
#
# Gurusamy Sarathy <gsar@umich.edu>
# Raphael Manfredi <Raphael_Manfredi@grenoble.hp.com>
#

require 5.004;
use strict;

####################################################################
package MLDBM::Serializer;	## deferred

use Carp;

#
# The serialization interface comprises of just three methods:
# new(), serialize() and deserialize().  Only the last two are
# _required_ to be implemented by any MLDBM serialization wrapper.
#

sub new { bless {}, shift };

sub serialize { confess "deferred" };

sub deserialize { confess "deferred" };


#
# Attributes:
#
#    dumpmeth:
#	the preferred dumping method.
#
#    removetaint:
#	untainting flag; when true, data will be untainted after
#	extraction from the database.
#
#    key:
#	the magic string used to recognize non-natively stored data.
#
# Attribute access methods:
#
#	These defaults allow readonly access. Sub-class may override
#	them to allow write access if any of these attributes
#	makes sense for it.
#

sub DumpMeth	{
    my $s = shift;
    confess "can't set dumpmeth with " . ref($s) if @_;
    $s->_attrib('dumpmeth');
}

sub RemoveTaint	{
    my $s = shift;
    confess "can't set untaint with " . ref($s) if @_;
    $s->_attrib('removetaint');
}

sub Key	{
    my $s = shift;
    confess "can't set key with " . ref($s) if @_;
    $s->_attrib('key');
}

sub _attrib {
    my ($s, $a, $v) = @_;
    if (ref $s and @_ > 2) {
	$s->{$a} = $v;
	return $s;
    }
    $s->{$a};
}

####################################################################
package MLDBM;

$MLDBM::VERSION = $MLDBM::VERSION = '2.00';

require Tie::Hash;
@MLDBM::ISA = 'Tie::Hash';

use Carp;

#
# the DB package to use (we default to SDBM since it comes with perl)
# you might want to change this default to something more efficient
# like DB_File (you can always override it in the use list)
#
$MLDBM::UseDB		= "SDBM_File"		unless $MLDBM::UseDB;
$MLDBM::Serializer	= 'Data::Dumper'	unless $MLDBM::Serializer;
$MLDBM::Key		= '$MlDbM'		unless $MLDBM::Key;
$MLDBM::DumpMeth	= ""			unless $MLDBM::DumpMeth;
$MLDBM::RemoveTaint	= 0			unless $MLDBM::RemoveTaint;

#
# A private way to load packages at runtime.
my $loadpack = sub {
    my $pack = shift;
    $pack =~ s|::|/|g;
    $pack .= ".pm";
    eval { require $pack };
    if ($@) {
	carp "MLDBM error: " . 
	  "Please make sure $pack is a properly installed package.\n" .
	    "\tPerl says: \"$@\"";
	return undef;
    }
    1;
};


#
# TIEHASH interface methods
#
sub TIEHASH {
    my $c = shift;
    my $s = bless {}, $c;

    #
    # Create the right serializer object.
    my $szr = $MLDBM::Serializer;
    unless (ref $szr) {
	$szr = "MLDBM::Serializer::$szr"	# allow convenient short names
	  unless $szr =~ /^MLDBM::Serializer::/;
	&$loadpack($szr) or return undef;
	$szr = $szr->new($MLDBM::DumpMeth,
			 $MLDBM::RemoveTaint,
			 $MLDBM::Key);
    }
    $s->Serializer($szr);

    #
    # Create the right TIEHASH  object.
    my $db = $MLDBM::UseDB;
    unless (ref $db) {
	&$loadpack($db) or return undef;
	$db = $db->TIEHASH(@_)
	  or carp "MLDBM error: Second level tie failed, \"$!\""
	    and return undef;
    }
    $s->UseDB($db);

    return $s;
}

sub FETCH {
    my ($s, $k) = @_;
    my $ret = $s->{DB}->FETCH($k);
    $s->{SR}->deserialize($ret);
}

sub STORE {
    my ($s, $k, $v) = @_;
    $v = $s->{SR}->serialize($v);
    $s->{DB}->STORE($k, $v);
}

sub DELETE	{ my $s = shift; $s->{DB}->DELETE(@_); }
sub FIRSTKEY	{ my $s = shift; $s->{DB}->FIRSTKEY(@_); }
sub NEXTKEY	{ my $s = shift; $s->{DB}->NEXTKEY(@_); }
sub EXISTS	{ my $s = shift; $s->{DB}->EXISTS(@_); }
sub CLEAR	{ my $s = shift; $s->{DB}->CLEAR(@_); }

sub new		{ &TIEHASH }

#
# delegate messages to the underlying DBM
#
sub AUTOLOAD {
    return if $MLDBM::AUTOLOAD =~ /::DESTROY$/;
    my $s = shift;
    if (ref $s) {			# twas a method call
	my $dbname = ref($s->{DB});
	# permit inheritance
	$MLDBM::AUTOLOAD =~ s/^.*::([^:]+)$/$dbname\:\:$1/;
	$s->{DB}->$MLDBM::AUTOLOAD(@_);
    }
}

#
# delegate messages to the underlying Serializer
#
sub DumpMeth	{ my $s = shift; $s->{SR}->DumpMeth(@_); }
sub RemoveTaint	{ my $s = shift; $s->{SR}->RemoveTaint(@_); }
sub Key		{ my $s = shift; $s->{SR}->Key(@_); }

#
# get/set the DB object
#
sub UseDB 	{ my $s = shift; @_ ? ($s->{DB} = shift) : $s->{DB}; }

#
# get/set the Serializer object
#
sub Serializer	{ my $s = shift; @_ ? ($s->{SR} = shift) : $s->{SR}; }

#
# stuff to do at 'use' time
#
sub import {
    my ($pack, $dbpack, $szr, $dumpmeth, $removetaint, $key) = @_;
    $MLDBM::UseDB = $dbpack if defined $dbpack and $dbpack;
    $MLDBM::Serializer = $szr if defined $szr and $szr;
    # undocumented, may change!
    $MLDBM::DumpMeth = $dumpmeth if defined $dumpmeth;
    $MLDBM::RemoveTaint = $removetaint if defined $removetaint;
    $MLDBM::Key = $key if defined $key and $key;
}

1;

__END__

=head1 NAME

MLDBM - store multi-level hash structure in single level tied hash

=head1 SYNOPSIS

    use MLDBM;				# this gets the default, SDBM
    #use MLDBM qw(DB_File FreezeThaw);	# use FreezeThaw for serializing
    #use MLDBM qw(DB_File Storable);	# use Storable for serializing
    
    $dbm = tie %o, 'MLDBM' [..other DBM args..] or die $!;

=head1 DESCRIPTION

This module can serve as a transparent interface to any TIEHASH package
that is required to store arbitrary perl data, including nested references.
Thus, this module can be used for storing references and other arbitrary data
within DBM databases.

It works by serializing the references in the hash into a single string. In the
underlying TIEHASH package (usually a DBM database), it is this string that
gets stored.  When the value is fetched again, the string is deserialized to
reconstruct the data structure into memory.

For historical and practical reasons, it requires the B<Data::Dumper> package,
available at any CPAN site. B<Data::Dumper> gives you really nice-looking dumps of
your data structures, in case you wish to look at them on the screen, and
it was the only serializing engine before version 2.00.  However, as of version
2.00, you can use any of B<Data::Dumper>, B<FreezeThaw> or B<Storable> to
perform the underlying serialization, as hinted at by the L<SYNOPSIS> overview
above.  Using B<Storable> is usually much faster than the other methods.

See the L<BUGS> section for important limitations.

=head2 Changing the Defaults

B<MLDBM> relies on an underlying TIEHASH implementation (usually a
DBM package), and an underlying serialization package.  The respective
defaults are B<SDBM_File> and D<Data::Dumper>.  Both of these defaults
can be changed.  Changing the B<SDBM_File> default is strongly recommended.
See L<WARNINGS> below.

Three serialization wrappers are currently supported: B<Data::Dumper>,
B<Storable>, and B<FreezeThaw>.  Additional serializers can be
supported by writing a wrapper that implements the interface required by
B<MLDBM::Serializer>.  See the supported wrappers and the B<MLDBM::Serializer>
source for details.

In the following, I<$OBJ> stands for the tied object, as in:

	$obj = tie %o, ....
	$obj = tied %o;

=over 4

=item $MLDBM::UseDB	I<or>	I<$OBJ>->UseDB(I<[TIEDOBJECT]>)

The global C<$MLDBM::UseDB> can be set to default to something other than
C<SDBM_File>, in case you have a more efficient DBM, or if you want to use
this with some other TIEHASH implementation.  Alternatively, you can specify
the name of the package at C<use> time, as the first "parameter".
Nested module names can be specified as "Foo::Bar".

The corresponding method call returns the underlying TIEHASH object when
called without arguments.  It can be called with any object that
implements Perl's TIEHASH interface, to set that value.

=item $MLDBM::Serializer	I<or>	I<$OBJ>->Serializer(I<[SZROBJECT]>)

The global C<$MLDBM::Serializer> can be set to the name of the serializing
package to be used. Currently can be set to one of C<Data::Dumper>,
C<Storable>, or C<FreezeThaw>. Defaults to C<Data::Dumper>.  Alternatively,
you can specify the name of the serializer package at C<use> time, as the
second "parameter".

The corresponding method call returns the underlying MLDBM serializer object
when called without arguments.  It can be called with an object that
implements the MLDBM serializer interface, to set that value.

=back

=head2 Controlling Serializer Properties

These methods are meant to supply an interface to the properties of the
underlying serializer used.  Do B<not> call or set them without
understanding the consequences in full.  The defaults are usually sensible.

Not all of these necessarily apply to all the supplied serializers, so we
specify when to apply them.  Failure to respect this will usually lead to
an exception.

=over 4

=item $MLDBM::DumpMeth	I<or>  I<$OBJ>->DumpMeth(I<[METHNAME]>)

If the serializer provides alternative serialization methods, this
can be used to set them.

With B<Data::Dumper> (which offers a pure Perl and an XS verion
of its serializing routine), this is set to C<Dumpxs> by default if that
is supported in your installation.  Otherwise, defaults to the slower
C<Dump> method.

With B<Storable>, a value of C<portable> requests that serialization be
architecture neutral, i.e. the deserialization can later occur on another
platform. Of course, this only makes sense if your database files are
themselves architecture neutral.  By default, native format is used for
greater serializing speed in B<Storable>.  Both B<Data::Dumper> and
B<FreezeThaw> are always architecture neutral.

B<FreezeThaw> does not honor this attribute.

=item $MLDBM::Key  I<or>  I<$OBJ>->Key(I<[KEYSTRING]>)

If the serializer only deals with part of the data (perhaps because
the TIEHASH object can natively store some types of data), it may need
a unique key string to recognize the data it handles.  This can be used
to set that string.  Best left alone.

Defaults to the magic string used to recognize MLDBM data. It is a six
character wide, unique string. This is best left alone, unless you know
what you are doing. 

B<Storable> and B<FreezeThaw> do not honor this attribute.

=item $MLDBM::RemoveTaint  I<or>  I<$OBJ>->RemoveTaint(I<[BOOL]>)

If the serializer can optionally untaint any retrieved data subject to
taint checks in Perl, this can be used to request that feature.  Data
that comes from external sources (like disk-files) must always be
viewed with caution, so use this only when you are sure that that is
not an issue.

B<Data::Dumper> uses C<eval()> to deserialize and is therefore subject to
taint checks.  Can be set to a true value to make the B<Data::Dumper>
serializer untaint the data retrieved. It is not enabled by default.
Use with care.

B<Storable> and B<FreezeThaw> do not honor this attribute.

=back

=head1 EXAMPLES

Here is a simple example.  Note that does not depend upon the underlying
serializing package--most real life examples should not, usually.

    use MLDBM;				# this gets SDBM and Data::Dumper
    #use MLDBM qw(SDBM_File Storable);	# SDBM and Storable
    use Fcntl;				# to get 'em constants
     
    $dbm = tie %o, 'MLDBM', 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
    
    $c = [\ 'c'];
    $b = {};
    $a = [1, $b, $c];
    $b->{a} = $a;
    $b->{b} = $a->[1];
    $b->{c} = $a->[2];
    @o{qw(a b c)} = ($a, $b, $c);
    
    #
    # to see what was stored
    #
    use Data::Dumper;
    print Data::Dumper->Dump([@o{qw(a b c)}], [qw(a b c)]);
    
    #
    # to modify data in a substructure
    #
    $tmp = $o{a};
    $tmp->[0] = 'foo';
    $o{a} = $tmp;
    
    #
    # can access the underlying DBM methods transparently
    #
    #print $dbm->fd, "\n";		# DB_File method

Here is another small example using Storable, in a portable format:

    use MLDBM qw(DB_File Storable);	# DB_File and Storable
    
    tie %o, 'MLDBM', 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
    
    (tied %o)->DumpMeth('portable');	# Ask for portable binary
    $o{'ENV'} = \%ENV;			# Stores the whole environment
    

=head1 BUGS

=over 4

=item 1.

Adding or altering substructures to a hash value is not entirely transparent
in current perl.  If you want to store a reference or modify an existing
reference value in the DBM, it must first be retrieved and stored in a
temporary variable for further modifications.  In particular, something like
this will NOT work properly:

	$mldb{key}{subkey}[3] = 'stuff';	# won't work

Instead, that must be written as:

	$tmp = $mldb{key};			# retrieve value
	$tmp->{subkey}[3] = 'stuff';
	$mldb{key} = $tmp;			# store value

This limitation exists because the perl TIEHASH interface currently has no
support for multidimensional ties.

=item 2.

The B<Data::Dumper> serializer uses eval().  A lot.  Try the B<Storable>
serializer, which is generally the most efficient.

=back

=head1 WARNINGS

=over 4

=item 1.

Many DBM implementations have arbitrary limits on the size of records
that can be stored.  For example, SDBM and many ODBM or NDBM
implementations have a default limit of 1024 bytes for the size of a
record.  MLDBM can easily exceed these limits when storing large data
structures, leading to mysterious failures.  Although SDBM_File is
used by MLDBM by default, it is not a good choice if you're storing
large data structures.  Berkeley DB and GDBM both do not have these
limits, so I recommend using either of those instead.

=item 2.

MLDBM does well with data structures that are not too deep and not
too wide.  You also need to be careful about how many C<FETCH>es your
code actually ends up doing.  Meaning, you should get the most mileage
out of a C<FETCH> by holding on to the highest level value for as long
as you need it.  Remember that every toplevel access of the tied hash,
for example C<$mldb{foo}>, translates to a MLDBM C<FETCH()> call.

Too often, people end up writing something like this:

        tie %h, 'MLDBM', ...;
        for my $k (keys %{$h{something}}) {
            print $h{something}{$k}[0]{foo}{bar};  # FETCH _every_ time!
        }

when it should be written this for efficiency:

        tie %h, 'MLDBM', ...;
        my $root = $h{something};                  # FETCH _once_
        for my $k (keys %$root) {
            print $k->[0]{foo}{bar};
        }


=back

=head1 AUTHORS

Gurusamy Sarathy <F<gsar@umich.edu>>.

Support for multiple serializing packages by
Raphael Manfredi <F<Raphael_Manfredi@grenoble.hp.com>>.

Copyright (c) 1995-98 Gurusamy Sarathy.  All rights reserved.

Copyright (c) 1998 Raphael Manfredi.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 2.00	10 May 1998

=head1 SEE ALSO

perl(1), perltie(1), perlfunc(1), Data::Dumper(3), FreezeThaw(3), Storable(3).

=cut
