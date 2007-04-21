package Hash::Util::FieldHash;

use 5.009004;
use strict;
use warnings;
use Scalar::Util qw( reftype);

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [ qw(
        fieldhash
        fieldhashes
    )],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.02';

{
    require XSLoader;
    my %ob_reg; # private object registry
    sub _ob_reg { \ %ob_reg }
    XSLoader::load('Hash::Util::FieldHash', $VERSION);
}

sub fieldhash (\%) {
    for ( shift ) {
        return unless ref() && reftype( $_) eq 'HASH';
        return $_ if Hash::Util::FieldHash::_fieldhash( $_, 0);
        return $_ if Hash::Util::FieldHash::_fieldhash( $_, 1);
        return;
    }
}

sub fieldhashes { map &fieldhash( $_), @_ }

1;
__END__

=head1 NAME

Hash::Util::FieldHash - Associate references with data

=head1 SYNOPSIS

  use Hash::Util qw(fieldhash fieldhashes);

  # Create a single field hash
  fieldhash my %foo;

  # Create three at once...
  fieldhashes \ my(%foo, %bar, %baz);
  # ...or any number
  fieldhashes @hashrefs;

=head1 Functions

Two functions generate field hashes:

=over

=item fieldhash

    fieldhash %hash;

Creates a single field hash.  The argument must be a hash.  Returns
a reference to the given hash if successful, otherwise nothing.

=item fieldhashes

    fieldhashes @hashrefs;

Creates any number of field hashes.  Arguments must be hash references.
Returns the converted hashrefs in list context, their number in scalar
context.

=back

=head1 Description

=head2 Features

Field hashes have three basic features:

=over

=item Key exchange

If a I<reference> is used as a field hash key, it is replaced by
the integer value of the reference address.

=item Thread support

In a new I<thread> a field hash is updated so that its keys reflect
the new reference addresses of the original objects.

=item Garbage collection

When a reference goes I<stale> after having been used as a field hash key,
the hash entry will be deleted.

=back

Field hashes are designed to maintain an association of a reference
with a value. The association is independent of the bless status of
the key, it is thread safe and garbage-collected.  These properties
are desirable in the construction of inside-out classes.

When used with keys that are plain scalars (not references), field
hashes behave like normal hashes.

=head2 Rationale

The association of a reference (namely an object) with a value is
central to the concept of inside-out classes.  These classes don't
store the values of object variables (fields) inside the object itself,
but outside, as it were, in private hashes keyed by the object.

Normal hashes can be used for the purpose, but turn out to have
some disadvantages:

=over

=item Stringification

The stringification of references depends on the bless status of the
reference.  A plain hash reference C<$ref> may stringify as C<HASH(0x1801018)>,
but after being blessed into class C<foo> the same reference will look like
as C<foo=HASH(0x1801018)>, unless class C<foo> overloads stringification,
in which case it may show up as C<wurzelzwerg>.  In a normal hash, the
stringified reference wouldn't be found again after the blessing.

Bypassing stringification by use of C<Scalar::Util::refaddr> has been
used to correct this.  Field hashes automatically stringify their
keys to the reference address in decimal.

=item Thread Dependency

When a new thread is created, the Perl interpreter is cloned, which
implies that all variables change their reference address.  Thus,
in a daughter thread, the "same" reference C<$ref> contains a different
address, but the cloned hash still holds the key based on the original
address.  Again, the association is broken.

A C<CLONE> method is required to update the hash on thread creation.
Field hashes come with an appropriate C<CLONE>.

=item Garbage Collection

When a reference (an object) is used as a hash key, the entry stays
in the hash when the object eventually goes out of scope.  That can result
in a memory leak because the data associated with the object is not
freed.  Worse than that, it can lead to a false association if the
reference address of the original object is later re-used.  This
is not a remote possibility, address re-use happens all the time and
is a certainty under many conditions.

If the references in question are indeed objects, a C<DESTROY> method
I<must> clean up hashes that the object uses for storage.  Special
methods are needed when unblessed references can occur.

Field hashes have garbage collection built in.  If a reference
(blessed or unblessed) goes out of scope, corresponding entries
will be deleted from all field hashes.

=back

Thus, an inside-out class based on field hashes doesn't need a C<DESTROY>
method, nor a C<CLONE> method for thread support.  That facilitates the
construction considerably.

=head2 How to use

Traditionally, the definition of an inside-out class contains a bare
block inside which a number of lexical hashes are declared and the
basic accessor methods defined, usually through C<Scalar::Util::refaddr>.
Further methods may be defined outside this block.  There has to be
a DESTROY method and, for thread support, a CLONE method.

When field hashes are used, the basic structure reamins the same.
Each lexical hash will be made a field hash.  The call to C<refaddr>
can be omitted from the accessor methods.  DESTROY and CLONE methods
are not necessary.

If you have an existing inside-out class, simply making all hashes
field hashes with no other change should make no difference.  Through
the calls to C<refaddr> or equivalent, the field hashes never get to
see a reference and work like normal hashes.  Your DESTROY (and
CLONE) methods are still needed.

To make the field hashes kick in, it is easiest to redefine C<refaddr>
as

    sub refaddr { shift }

instead of importing it from C<Scalar::Util>.  It should now be possible
to disable DESTROY and CLONE.  Note that while it isn't disabled,
DESTROY will be called before the garbage collection of field hashes,
so it will be invoked with a functional object and will continue to
function.

It is not desirable to import the functions C<fieldhash> and/or
C<fieldhashes> into every class that is going to use them.  They
are only used once to set up the class.  When the class is up and running,
these functions serve no more purpose.

If there are only a few field hashes to declare, it is simplest to

    use Hash::Util::FieldHash;

early and call the functions qualified:

    Hash::Util::FieldHash::fieldhash my %foo;

Otherwise, import the functions into a convenient package like
C<HUF> or, more generic, C<Aux>

    {
        package Aux;
        use Hash::Util::FieldHash ':all';
    }

and call

    Aux::fieldhash my %foo;

as needed.

=head2 Examples

Well... really only one example, and a rather trivial one at that.
There isn't much to exemplify.

=head3 A simple class...

The following example shows an utterly simple inside-out class
C<TimeStamp>, created using field hashes.  It has a single field,
incorporated as the field hash C<%time>.  Besides C<new> it has only
two methods: an initializer called C<stamp> that sets the field to
the current time, and a read-only accessor C<when> that returns the
time in C<localtime> format.

    # The class TimeStamp

    use Hash::Util::FieldHash;
    {
        package TimeStamp;

        Hash::Util::FieldHash::fieldhash my %time;

        sub stamp { $time{ $_[ 0]} = time; shift }       # initializer
        sub when { scalar localtime $time{ shift()} }    # read accessor
        sub new { bless( do { \ my $x }, shift)->stamp } # creator
    }

    # See if it works
    my $ts = TimeStamp->new;
    print $ts->when, "\n";

Remarkable about this class definition is what isn't there: there
is no C<DESTROY> method, inherited or local, and no C<CLONE> method
is needed to make it thread-safe.  Not to mention no need to call
C<refaddr> or something similar in the accessors.

=head3 ...in action

The outstanding property of inside-out classes is their "inheritability".
Like all inside-out classes, C<TimeStamp> is a I<universal base class>.
We can put it on the C<@ISA> list of arbitrary classes and its methods
will just work, no matter how the host class is constructed.  No traditional
Perl class allows that.  The following program demonstrates the feat:

    # Make a sample of objects to add time stamps to.

    use Math::Complex;
    use IO::Handle;

    my @objects = (
        Math::Complex->new( 12, 13),
        IO::Handle->new(),
        qr/abc/,                         # in class Regexp
        bless( [], 'Boing'),             # made up on the spot
        # add more
    );

    # Prepare for use with TimeStamp

    for ( @objects ) {
        no strict 'refs';
        push @{ ref() . '::ISA' }, 'TimeStamp';
    }

    # Now apply TimeStamp methods to all objects and show the result

    for my $obj ( @objects ) {
        $obj->stamp;
        report( $obj, $obj->when);
    }

    # print a description of the object and the result of ->when

    use Scalar::Util qw( reftype);
    sub report {
        my ( $obj, $when) = @_;
        my $msg = sprintf "This is a %s object(a %s), its time is %s",
            ref $obj,
            reftype $obj,
            $when;
        $msg =~ s/\ba(?= [aeiouAEIOU])/an/g; # grammar matters :)
        print "$msg\n";
    }

=head2 Garbage-Collected Hashes

Garbage collection in a field hash means that entries will "spontaneously"
disappear when the object that created them disappears.  That must be
borne in mind, especially when looping over a field hash.  If anything
you do inside the loop could cause an object to go out of scope, a
random key may be deleted from the hash you are looping over.  That
can throw the loop iterator, so it's best to cache a consistent snapshot
of the keys and/or values and loop over that.  You will still have to
check that a cached entry still exists when you get to it.

Garbage collection can be confusing when keys are created in a field hash
from normal scalars as well as references.  Once a reference is I<used> with
a field hash, the entry will be collected, even if it was later overwritten
with a plain scalar key (every positive integer is a candidate).  This
is true even if the original entry was deleted in the meantime.  In fact,
deletion from a field hash, and also a test for existence constitute
I<use> in this sense and create a liability to delete the entry when
the reference goes out of scope.  If you happen to create an entry
with an identical key from a string or integer, that will be collected
instead.  Thus, mixed use of references and plain scalars as field hash
keys is not entirely supported.

=head1 Guts

To make C<Hash::Util::FieldHash> work, there were two changes to
F<perl> itself.  C<PERL_MAGIC_uvar> was made avaliable for hashes,
and weak references now call uvar C<get> magic after a weakref has been
cleared.  The first feature is used to make field hashes intercept
their keys upon access.  The second one triggers garbage collection.

=head2 The C<PERL_MAGIC_uvar> interface for hashes

C<PERL_MAGIC_uvar> I<get> magic is called from C<hv_fetch_common> and
C<hv_delete_common> through the function C<hv_magic_uvar_xkey>, which
defines the interface.  The call happens for hashes with "uvar" magic
if the C<ufuncs> structure has equal values in the C<uf_val> and C<uf_set>
fields.  Hashes are unaffected if (and as long as) these fields
hold different values.

Upon the call, the C<mg_obj> field will hold the hash key to be accessed.
Upon return, the C<SV*> value in C<mg_obj> will be used in place of the
original key in the hash access.  The integer index value in the first
parameter will be the C<action> value from C<hv_fetch_common>, or -1
if the call is from C<hv_delete_common>.

This is a template for a function suitable for the C<uf_val> field in
a C<ufuncs> structure for this call.  The C<uf_set> and C<uf_index>
fields are irrelevant.

    IV watch_key(pTHX_ IV action, SV* field) {
        MAGIC* mg = mg_find(field, PERL_MAGIC_uvar);
        SV* keysv = mg->mg_obj;
        /* Do whatever you need to.  If you decide to
           supply a different key newkey, return it like this
        */
        sv_2mortal(newkey);
        mg->mg_obj = newkey;
        return 0;
    }

=head2 Weakrefs call uvar magic

When a weak reference is stored in an C<SV> that has "uvar" magic, C<set>
magic is called after the reference has gone stale.  This hook can be
used to trigger further garbage-collection activities associated with
the referenced object.

=head2 How field hashes work

The three features of key hashes, I<key replacement>, I<thread support>,
and I<garbage collection> are supported by a data structure called
the I<object registry>.  This is a private hash where every object
is stored.  An "object" in this sense is any reference (blessed or
unblessed) that has been used as a field hash key.

The object registry keeps track of references that have been used as
field hash keys.  The keys are generated from the reference address
like in a field hash (though the registry isn't a field hash).  Each
value is a weak copy of the original reference, stored in an C<SV> that
is itself magical (C<PERL_MAGIC_uvar> again).  The magical structure
holds a list (another hash, really) of field hashes that the reference
has been used with.  When the weakref becomes stale, the magic is
activated and uses the list to delete the reference from all field
hashes it has been used with.  After that, the entry is removed from
the object registry itself.  Implicitly, that frees the magic structure
and the storage it has been using.

Whenever a reference is used as a field hash key, the object registry
is checked and a new entry is made if necessary.  The field hash is
then added to the list of fields this reference has used.

The object registry is also used to repair a field hash after thread
cloning.  Here, the entire object registry is processed.  For every
reference found there, the field hashes it has used are visited and
the entry is updated.

=head2 Internal function Hash::Util::FieldHash::_fieldhash

    # test if %hash is a field hash
    my $result = _fieldhash \ %hash, 0;

    # make %hash a field hash
    my $result = _fieldhash \ %hash, 1;

C<_fieldhash> is the internal function used to create field hashes.
It takes two arguments, a hashref and a mode.  If the mode is boolean
false, the hash is not changed but tested if it is a field hash.  If
the hash isn't a field hash the return value is boolean false.  If it
is, the return value indicates the mode of field hash.  When called with
a boolean true mode, it turns the given hash into a field hash of this
mode, returning the mode of the created field hash.  C<_fieldhash>
does not erase the given hash.

Currently there is only one type of field hash, and only the boolean
value of the mode makes a difference, but that may change.

=head1 AUTHOR

Anno Siegel, E<lt>anno4000@zrz.tu-berlin.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by (Anno Siegel)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
