;# $Id: Storable.pm,v 1.0.1.12 2001/08/28 21:51:51 ram Exp $
;#
;#  Copyright (c) 1995-2000, Raphael Manfredi
;#  
;#  You may redistribute only under the same terms as Perl 5, as specified
;#  in the README file that comes with the distribution.
;#
;# $Log: Storable.pm,v $
;# Revision 1.0.1.12  2001/08/28 21:51:51  ram
;# patch13: fixed truncation race with lock_retrieve() in lock_store()
;#
;# Revision 1.0.1.11  2001/07/01 11:22:14  ram
;# patch12: systematically use "=over 4" for POD linters
;# patch12: updated version number
;#
;# Revision 1.0.1.10  2001/03/15 00:20:25  ram
;# patch11: updated version number
;#
;# Revision 1.0.1.9  2001/02/17 12:37:32  ram
;# patch10: forgot to increase version number at previous patch
;#
;# Revision 1.0.1.8  2001/02/17 12:24:37  ram
;# patch8: fixed incorrect error message
;#
;# Revision 1.0.1.7  2001/01/03 09:39:02  ram
;# patch7: added CAN_FLOCK to determine whether we can flock() or not
;#
;# Revision 1.0.1.6  2000/11/05 17:20:25  ram
;# patch6: increased version number
;#
;# Revision 1.0.1.5  2000/10/26 17:10:18  ram
;# patch5: documented that store() and retrieve() can return undef
;# patch5: added paragraph explaining the auto require for thaw hooks
;#
;# Revision 1.0.1.4  2000/10/23 18:02:57  ram
;# patch4: protected calls to flock() for dos platform
;# patch4: added logcarp emulation if they don't have Log::Agent
;#
;# Revision 1.0.1.3  2000/09/29 19:49:01  ram
;# patch3: updated version number
;#
;# Revision 1.0.1.2  2000/09/28 21:42:51  ram
;# patch2: added lock_store lock_nstore lock_retrieve
;#
;# Revision 1.0.1.1  2000/09/17 16:46:21  ram
;# patch1: documented that doubles are stringified by nstore()
;# patch1: added Salvador Ortiz Garcia in CREDITS section
;#
;# Revision 1.0  2000/09/01 19:40:41  ram
;# Baseline for first official release.
;#

require DynaLoader;
require Exporter;
package Storable; @ISA = qw(Exporter DynaLoader);

@EXPORT = qw(store retrieve);
@EXPORT_OK = qw(
	nstore store_fd nstore_fd fd_retrieve
	freeze nfreeze thaw
	dclone
	retrieve_fd
	lock_store lock_nstore lock_retrieve
);

use AutoLoader;
use vars qw($forgive_me $VERSION);

$VERSION = '1.013';
*AUTOLOAD = \&AutoLoader::AUTOLOAD;		# Grrr...

#
# Use of Log::Agent is optional
#

eval "use Log::Agent";

unless (defined @Log::Agent::EXPORT) {
	eval q{
		sub logcroak {
			require Carp;
			Carp::croak(@_);
		}
		sub logcarp {
			require Carp;
			Carp::carp(@_);
		}
	};
}

#
# They might miss :flock in Fcntl
#

BEGIN {
	require Fcntl;
	if (exists $Fcntl::EXPORT_TAGS{'flock'}) {
		Fcntl->import(':flock');
	} else {
		eval q{
			sub LOCK_SH ()	{1}
			sub LOCK_EX ()	{2}
		};
	}
}

sub logcroak;
sub logcarp;

sub retrieve_fd { &fd_retrieve }		# Backward compatibility

#
# Determine whether locking is possible, but only when needed.
#

my $CAN_FLOCK;

sub CAN_FLOCK {
	return $CAN_FLOCK if defined $CAN_FLOCK;
	require Config; import Config;
	return $CAN_FLOCK =
		$Config{'d_flock'} ||
		$Config{'d_fcntl_can_lock'} ||
		$Config{'d_lockf'};
}

bootstrap Storable;
1;
__END__

#
# store
#
# Store target object hierarchy, identified by a reference to its root.
# The stored object tree may later be retrieved to memory via retrieve.
# Returns undef if an I/O error occurred, in which case the file is
# removed.
#
sub store {
	return _store(\&pstore, @_, 0);
}

#
# nstore
#
# Same as store, but in network order.
#
sub nstore {
	return _store(\&net_pstore, @_, 0);
}

#
# lock_store
#
# Same as store, but flock the file first (advisory locking).
#
sub lock_store {
	return _store(\&pstore, @_, 1);
}

#
# lock_nstore
#
# Same as nstore, but flock the file first (advisory locking).
#
sub lock_nstore {
	return _store(\&net_pstore, @_, 1);
}

# Internal store to file routine
sub _store {
	my $xsptr = shift;
	my $self = shift;
	my ($file, $use_locking) = @_;
	logcroak "not a reference" unless ref($self);
	logcroak "wrong argument number" unless @_ == 2;	# No @foo in arglist
	local *FILE;
	if ($use_locking) {
		open(FILE, ">>$file") || logcroak "can't write into $file: $!";
		unless (&CAN_FLOCK) {
			logcarp "Storable::lock_store: fcntl/flock emulation broken on $^O";
			return undef;
		}
		flock(FILE, LOCK_EX) ||
			logcroak "can't get exclusive lock on $file: $!";
		truncate FILE, 0;
		# Unlocking will happen when FILE is closed
	} else {
		open(FILE, ">$file") || logcroak "can't create $file: $!";
	}
	binmode FILE;				# Archaic systems...
	my $da = $@;				# Don't mess if called from exception handler
	my $ret;
	# Call C routine nstore or pstore, depending on network order
	eval { $ret = &$xsptr(*FILE, $self) };
	close(FILE) or $ret = undef;
	unlink($file) or warn "Can't unlink $file: $!\n" if $@ || !defined $ret;
	logcroak $@ if $@ =~ s/\.?\n$/,/;
	$@ = $da;
	return $ret ? $ret : undef;
}

#
# store_fd
#
# Same as store, but perform on an already opened file descriptor instead.
# Returns undef if an I/O error occurred.
#
sub store_fd {
	return _store_fd(\&pstore, @_);
}

#
# nstore_fd
#
# Same as store_fd, but in network order.
#
sub nstore_fd {
	my ($self, $file) = @_;
	return _store_fd(\&net_pstore, @_);
}

# Internal store routine on opened file descriptor
sub _store_fd {
	my $xsptr = shift;
	my $self = shift;
	my ($file) = @_;
	logcroak "not a reference" unless ref($self);
	logcroak "too many arguments" unless @_ == 1;	# No @foo in arglist
	my $fd = fileno($file);
	logcroak "not a valid file descriptor" unless defined $fd;
	my $da = $@;				# Don't mess if called from exception handler
	my $ret;
	# Call C routine nstore or pstore, depending on network order
	eval { $ret = &$xsptr($file, $self) };
	logcroak $@ if $@ =~ s/\.?\n$/,/;
	$@ = $da;
	return $ret ? $ret : undef;
}

#
# freeze
#
# Store oject and its hierarchy in memory and return a scalar
# containing the result.
#
sub freeze {
	_freeze(\&mstore, @_);
}

#
# nfreeze
#
# Same as freeze but in network order.
#
sub nfreeze {
	_freeze(\&net_mstore, @_);
}

# Internal freeze routine
sub _freeze {
	my $xsptr = shift;
	my $self = shift;
	logcroak "not a reference" unless ref($self);
	logcroak "too many arguments" unless @_ == 0;	# No @foo in arglist
	my $da = $@;				# Don't mess if called from exception handler
	my $ret;
	# Call C routine mstore or net_mstore, depending on network order
	eval { $ret = &$xsptr($self) };
	logcroak $@ if $@ =~ s/\.?\n$/,/;
	$@ = $da;
	return $ret ? $ret : undef;
}

#
# retrieve
#
# Retrieve object hierarchy from disk, returning a reference to the root
# object of that tree.
#
sub retrieve {
	_retrieve($_[0], 0);
}

#
# lock_retrieve
#
# Same as retrieve, but with advisory locking.
#
sub lock_retrieve {
	_retrieve($_[0], 1);
}

# Internal retrieve routine
sub _retrieve {
	my ($file, $use_locking) = @_;
	local *FILE;
	open(FILE, $file) || logcroak "can't open $file: $!";
	binmode FILE;							# Archaic systems...
	my $self;
	my $da = $@;							# Could be from exception handler
	if ($use_locking) {
		unless (&CAN_FLOCK) {
			logcarp "Storable::lock_store: fcntl/flock emulation broken on $^O";
			return undef;
		}
		flock(FILE, LOCK_SH) || logcroak "can't get shared lock on $file: $!";
		# Unlocking will happen when FILE is closed
	}
	eval { $self = pretrieve(*FILE) };		# Call C routine
	close(FILE);
	logcroak $@ if $@ =~ s/\.?\n$/,/;
	$@ = $da;
	return $self;
}

#
# fd_retrieve
#
# Same as retrieve, but perform from an already opened file descriptor instead.
#
sub fd_retrieve {
	my ($file) = @_;
	my $fd = fileno($file);
	logcroak "not a valid file descriptor" unless defined $fd;
	my $self;
	my $da = $@;							# Could be from exception handler
	eval { $self = pretrieve($file) };		# Call C routine
	logcroak $@ if $@ =~ s/\.?\n$/,/;
	$@ = $da;
	return $self;
}

#
# thaw
#
# Recreate objects in memory from an existing frozen image created
# by freeze.  If the frozen image passed is undef, return undef.
#
sub thaw {
	my ($frozen) = @_;
	return undef unless defined $frozen;
	my $self;
	my $da = $@;							# Could be from exception handler
	eval { $self = mretrieve($frozen) };	# Call C routine
	logcroak $@ if $@ =~ s/\.?\n$/,/;
	$@ = $da;
	return $self;
}

=head1 NAME

Storable - persistency for perl data structures

=head1 SYNOPSIS

 use Storable;
 store \%table, 'file';
 $hashref = retrieve('file');

 use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);

 # Network order
 nstore \%table, 'file';
 $hashref = retrieve('file');	# There is NO nretrieve()

 # Storing to and retrieving from an already opened file
 store_fd \@array, \*STDOUT;
 nstore_fd \%table, \*STDOUT;
 $aryref = fd_retrieve(\*SOCKET);
 $hashref = fd_retrieve(\*SOCKET);

 # Serializing to memory
 $serialized = freeze \%table;
 %table_clone = %{ thaw($serialized) };

 # Deep (recursive) cloning
 $cloneref = dclone($ref);

 # Advisory locking
 use Storable qw(lock_store lock_nstore lock_retrieve)
 lock_store \%table, 'file';
 lock_nstore \%table, 'file';
 $hashref = lock_retrieve('file');

=head1 DESCRIPTION

The Storable package brings persistency to your perl data structures
containing SCALAR, ARRAY, HASH or REF objects, i.e. anything that can be
convenientely stored to disk and retrieved at a later time.

It can be used in the regular procedural way by calling C<store> with
a reference to the object to be stored, along with the file name where
the image should be written.
The routine returns C<undef> for I/O problems or other internal error,
a true value otherwise. Serious errors are propagated as a C<die> exception.

To retrieve data stored to disk, use C<retrieve> with a file name,
and the objects stored into that file are recreated into memory for you,
a I<reference> to the root object being returned. In case an I/O error
occurs while reading, C<undef> is returned instead. Other serious
errors are propagated via C<die>.

Since storage is performed recursively, you might want to stuff references
to objects that share a lot of common data into a single array or hash
table, and then store that object. That way, when you retrieve back the
whole thing, the objects will continue to share what they originally shared.

At the cost of a slight header overhead, you may store to an already
opened file descriptor using the C<store_fd> routine, and retrieve
from a file via C<fd_retrieve>. Those names aren't imported by default,
so you will have to do that explicitely if you need those routines.
The file descriptor you supply must be already opened, for read
if you're going to retrieve and for write if you wish to store.

	store_fd(\%table, *STDOUT) || die "can't store to stdout\n";
	$hashref = fd_retrieve(*STDIN);

You can also store data in network order to allow easy sharing across
multiple platforms, or when storing on a socket known to be remotely
connected. The routines to call have an initial C<n> prefix for I<network>,
as in C<nstore> and C<nstore_fd>. At retrieval time, your data will be
correctly restored so you don't have to know whether you're restoring
from native or network ordered data.  Double values are stored stringified
to ensure portability as well, at the slight risk of loosing some precision
in the last decimals.

When using C<fd_retrieve>, objects are retrieved in sequence, one
object (i.e. one recursive tree) per associated C<store_fd>.

If you're more from the object-oriented camp, you can inherit from
Storable and directly store your objects by invoking C<store> as
a method. The fact that the root of the to-be-stored tree is a
blessed reference (i.e. an object) is special-cased so that the
retrieve does not provide a reference to that object but rather the
blessed object reference itself. (Otherwise, you'd get a reference
to that blessed object).

=head1 MEMORY STORE

The Storable engine can also store data into a Perl scalar instead, to
later retrieve them. This is mainly used to freeze a complex structure in
some safe compact memory place (where it can possibly be sent to another
process via some IPC, since freezing the structure also serializes it in
effect). Later on, and maybe somewhere else, you can thaw the Perl scalar
out and recreate the original complex structure in memory.

Surprisingly, the routines to be called are named C<freeze> and C<thaw>.
If you wish to send out the frozen scalar to another machine, use
C<nfreeze> instead to get a portable image.

Note that freezing an object structure and immediately thawing it
actually achieves a deep cloning of that structure:

    dclone(.) = thaw(freeze(.))

Storable provides you with a C<dclone> interface which does not create
that intermediary scalar but instead freezes the structure in some
internal memory space and then immediatly thaws it out.

=head1 ADVISORY LOCKING

The C<lock_store> and C<lock_nstore> routine are equivalent to C<store>
and C<nstore>, only they get an exclusive lock on the file before
writing.  Likewise, C<lock_retrieve> performs as C<retrieve>, but also
gets a shared lock on the file before reading.

Like with any advisory locking scheme, the protection only works if
you systematically use C<lock_store> and C<lock_retrieve>.  If one
side of your application uses C<store> whilst the other uses C<lock_retrieve>,
you will get no protection at all.

The internal advisory locking is implemented using Perl's flock() routine.
If your system does not support any form of flock(), or if you share
your files across NFS, you might wish to use other forms of locking by
using modules like LockFile::Simple which lock a file using a filesystem
entry, instead of locking the file descriptor.

=head1 SPEED

The heart of Storable is written in C for decent speed. Extra low-level
optimization have been made when manipulating perl internals, to
sacrifice encapsulation for the benefit of a greater speed.

=head1 CANONICAL REPRESENTATION

Normally Storable stores elements of hashes in the order they are
stored internally by Perl, i.e. pseudo-randomly.  If you set
C<$Storable::canonical> to some C<TRUE> value, Storable will store
hashes with the elements sorted by their key.  This allows you to
compare data structures by comparing their frozen representations (or
even the compressed frozen representations), which can be useful for
creating lookup tables for complicated queries.

Canonical order does not imply network order, those are two orthogonal
settings.

=head1 ERROR REPORTING

Storable uses the "exception" paradigm, in that it does not try to workaround
failures: if something bad happens, an exception is generated from the
caller's perspective (see L<Carp> and C<croak()>).  Use eval {} to trap
those exceptions.

When Storable croaks, it tries to report the error via the C<logcroak()>
routine from the C<Log::Agent> package, if it is available.

Normal errors are reported by having store() or retrieve() return C<undef>.
Such errors are usually I/O errors (or truncated stream errors at retrieval).

=head1 WIZARDS ONLY

=head2 Hooks

Any class may define hooks that will be called during the serialization
and deserialization process on objects that are instances of that class.
Those hooks can redefine the way serialization is performed (and therefore,
how the symetrical deserialization should be conducted).

Since we said earlier:

    dclone(.) = thaw(freeze(.))

everything we say about hooks should also hold for deep cloning. However,
hooks get to know whether the operation is a mere serialization, or a cloning.

Therefore, when serializing hooks are involved,

    dclone(.) <> thaw(freeze(.))

Well, you could keep them in sync, but there's no guarantee it will always
hold on classes somebody else wrote.  Besides, there is little to gain in
doing so: a serializing hook could only keep one attribute of an object,
which is probably not what should happen during a deep cloning of that
same object.

Here is the hooking interface:

=over 4

=item C<STORABLE_freeze> I<obj>, I<cloning>

The serializing hook, called on the object during serialization.  It can be
inherited, or defined in the class itself, like any other method.

Arguments: I<obj> is the object to serialize, I<cloning> is a flag indicating
whether we're in a dclone() or a regular serialization via store() or freeze().

Returned value: A LIST C<($serialized, $ref1, $ref2, ...)> where $serialized
is the serialized form to be used, and the optional $ref1, $ref2, etc... are
extra references that you wish to let the Storable engine serialize.

At deserialization time, you will be given back the same LIST, but all the
extra references will be pointing into the deserialized structure.

The B<first time> the hook is hit in a serialization flow, you may have it
return an empty list.  That will signal the Storable engine to further
discard that hook for this class and to therefore revert to the default
serialization of the underlying Perl data.  The hook will again be normally
processed in the next serialization.

Unless you know better, serializing hook should always say:

    sub STORABLE_freeze {
        my ($self, $cloning) = @_;
        return if $cloning;         # Regular default serialization
        ....
    }

in order to keep reasonable dclone() semantics.

=item C<STORABLE_thaw> I<obj>, I<cloning>, I<serialized>, ...

The deserializing hook called on the object during deserialization.
But wait. If we're deserializing, there's no object yet... right?

Wrong: the Storable engine creates an empty one for you.  If you know Eiffel,
you can view C<STORABLE_thaw> as an alternate creation routine.

This means the hook can be inherited like any other method, and that
I<obj> is your blessed reference for this particular instance.

The other arguments should look familiar if you know C<STORABLE_freeze>:
I<cloning> is true when we're part of a deep clone operation, I<serialized>
is the serialized string you returned to the engine in C<STORABLE_freeze>,
and there may be an optional list of references, in the same order you gave
them at serialization time, pointing to the deserialized objects (which
have been processed courtesy of the Storable engine).

When the Storable engine does not find any C<STORABLE_thaw> hook routine,
it tries to load the class by requiring the package dynamically (using
the blessed package name), and then re-attempts the lookup.  If at that
time the hook cannot be located, the engine croaks.  Note that this mechanism
will fail if you define several classes in the same file, but perlmod(1)
warned you.

It is up to you to use these information to populate I<obj> the way you want.

Returned value: none.

=back

=head2 Predicates

Predicates are not exportable.  They must be called by explicitely prefixing
them with the Storable package name.

=over 4

=item C<Storable::last_op_in_netorder>

The C<Storable::last_op_in_netorder()> predicate will tell you whether
network order was used in the last store or retrieve operation.  If you
don't know how to use this, just forget about it.

=item C<Storable::is_storing>

Returns true if within a store operation (via STORABLE_freeze hook).

=item C<Storable::is_retrieving>

Returns true if within a retrieve operation, (via STORABLE_thaw hook).

=back

=head2 Recursion

With hooks comes the ability to recurse back to the Storable engine.  Indeed,
hooks are regular Perl code, and Storable is convenient when it comes to
serialize and deserialize things, so why not use it to handle the
serialization string?

There are a few things you need to know however:

=over 4

=item *

You can create endless loops if the things you serialize via freeze()
(for instance) point back to the object we're trying to serialize in the hook.

=item *

Shared references among objects will not stay shared: if we're serializing
the list of object [A, C] where both object A and C refer to the SAME object
B, and if there is a serializing hook in A that says freeze(B), then when
deserializing, we'll get [A', C'] where A' refers to B', but C' refers to D,
a deep clone of B'.  The topology was not preserved.

=back

That's why C<STORABLE_freeze> lets you provide a list of references
to serialize.  The engine guarantees that those will be serialized in the
same context as the other objects, and therefore that shared objects will
stay shared.

In the above [A, C] example, the C<STORABLE_freeze> hook could return:

	("something", $self->{B})

and the B part would be serialized by the engine.  In C<STORABLE_thaw>, you
would get back the reference to the B' object, deserialized for you.

Therefore, recursion should normally be avoided, but is nonetheless supported.

=head2 Deep Cloning

There is a new Clone module available on CPAN which implements deep cloning
natively, i.e. without freezing to memory and thawing the result.  It is
aimed to replace Storable's dclone() some day.  However, it does not currently
support Storable hooks to redefine the way deep cloning is performed.

=head1 EXAMPLES

Here are some code samples showing a possible usage of Storable:

	use Storable qw(store retrieve freeze thaw dclone);

	%color = ('Blue' => 0.1, 'Red' => 0.8, 'Black' => 0, 'White' => 1);

	store(\%color, '/tmp/colors') or die "Can't store %a in /tmp/colors!\n";

	$colref = retrieve('/tmp/colors');
	die "Unable to retrieve from /tmp/colors!\n" unless defined $colref;
	printf "Blue is still %lf\n", $colref->{'Blue'};

	$colref2 = dclone(\%color);

	$str = freeze(\%color);
	printf "Serialization of %%color is %d bytes long.\n", length($str);
	$colref3 = thaw($str);

which prints (on my machine):

	Blue is still 0.100000
	Serialization of %color is 102 bytes long.

=head1 WARNING

If you're using references as keys within your hash tables, you're bound
to disapointment when retrieving your data. Indeed, Perl stringifies
references used as hash table keys. If you later wish to access the
items via another reference stringification (i.e. using the same
reference that was used for the key originally to record the value into
the hash table), it will work because both references stringify to the
same string.

It won't work across a C<store> and C<retrieve> operations however, because
the addresses in the retrieved objects, which are part of the stringified
references, will probably differ from the original addresses. The
topology of your structure is preserved, but not hidden semantics
like those.

On platforms where it matters, be sure to call C<binmode()> on the
descriptors that you pass to Storable functions.

Storing data canonically that contains large hashes can be
significantly slower than storing the same data normally, as
temprorary arrays to hold the keys for each hash have to be allocated,
populated, sorted and freed.  Some tests have shown a halving of the
speed of storing -- the exact penalty will depend on the complexity of
your data.  There is no slowdown on retrieval.

=head1 BUGS

You can't store GLOB, CODE, FORMLINE, etc... If you can define
semantics for those operations, feel free to enhance Storable so that
it can deal with them.

The store functions will C<croak> if they run into such references
unless you set C<$Storable::forgive_me> to some C<TRUE> value. In that
case, the fatal message is turned in a warning and some
meaningless string is stored instead.

Setting C<$Storable::canonical> may not yield frozen strings that
compare equal due to possible stringification of numbers. When the
string version of a scalar exists, it is the form stored, therefore
if you happen to use your numbers as strings between two freezing
operations on the same data structures, you will get different
results.

When storing doubles in network order, their value is stored as text.
However, you should also not expect non-numeric floating-point values
such as infinity and "not a number" to pass successfully through a
nstore()/retrieve() pair.

As Storable neither knows nor cares about character sets (although it
does know that characters may be more than eight bits wide), any difference
in the interpretation of character codes between a host and a target
system is your problem.  In particular, if host and target use different
code points to represent the characters used in the text representation
of floating-point numbers, you will not be able be able to exchange
floating-point data, even with nstore().

=head1 CREDITS

Thank you to (in chronological order):

	Jarkko Hietaniemi <jhi@iki.fi>
	Ulrich Pfeifer <pfeifer@charly.informatik.uni-dortmund.de>
	Benjamin A. Holzman <bah@ecnvantage.com>
	Andrew Ford <A.Ford@ford-mason.co.uk>
	Gisle Aas <gisle@aas.no>
	Jeff Gresham <gresham_jeffrey@jpmorgan.com>
	Murray Nesbitt <murray@activestate.com>
	Marc Lehmann <pcg@opengroup.org>
	Justin Banks <justinb@wamnet.com>
	Jarkko Hietaniemi <jhi@iki.fi> (AGAIN, as perl 5.7.0 Pumpkin!)
	Salvador Ortiz Garcia <sog@msg.com.mx>
	Dominic Dunlop <domo@computer.org>
	Erik Haugan <erik@solbors.no>

for their bug reports, suggestions and contributions.

Benjamin Holzman contributed the tied variable support, Andrew Ford
contributed the canonical order for hashes, and Gisle Aas fixed
a few misunderstandings of mine regarding the Perl internals,
and optimized the emission of "tags" in the output streams by
simply counting the objects instead of tagging them (leading to
a binary incompatibility for the Storable image starting at version
0.6--older images are of course still properly understood).
Murray Nesbitt made Storable thread-safe.  Marc Lehmann added overloading
and reference to tied items support.

=head1 TRANSLATIONS

There is a Japanese translation of this man page available at
http://member.nifty.ne.jp/hippo2000/perltips/storable.htm ,
courtesy of Kawai, Takanori <kawai@nippon-rad.co.jp>.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Clone(3).

=cut

