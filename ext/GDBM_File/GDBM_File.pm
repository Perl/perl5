# GDBM_File.pm -- Perl 5 interface to GNU gdbm library.

=head1 NAME

GDBM_File - Perl5 access to the gdbm library.

=head1 SYNOPSIS

    use GDBM_File;
    [$db =] tie %hash, 'GDBM_File', $filename, &GDBM_WRCREAT, 0640;
    # Use the %hash array.

    $e = $db->errno;
    $e = $db->syserrno;
    $str = $db->strerror;
    $bool = $db->needs_recovery;

    $db->clear_error;

    $db->reorganize;
    $db->sync;

    $n = $db->count;

    $n = $db->flags;

    $str = $db->dbname;

    $db->cache_size;
    $db->cache_size($newsize);

    $n = $db->block_size;

    $bool = $db->sync_mode;
    $db->sync_mode($bool);

    $bool = $db->centfree;
    $db->centfree($bool);

    $bool = $db->coalesce;
    $db->coalesce($bool);

    $bool = $db->mmap;

    $size = $db->mmapsize;
    $db->mmapsize($newsize);

    $db->recover(%args);

    untie %hash ;

=head1 DESCRIPTION

B<GDBM_File> is a module which allows Perl programs to make use of the
facilities provided by the GNU gdbm library.  If you intend to use this
module you should really have a copy of the gdbm manualpage at hand.

Most of the libgdbm.a functions are available through the GDBM_File
interface.

Unlike Perl's built-in hashes, it is not safe to C<delete> the current
item from a GDBM_File tied hash while iterating over it with C<each>.
This is a limitation of the gdbm library.

=head1 STATIC METHODS

=head2 GDBM_version

    $str = GDBM_File->GDBM_version;
    @ar = GDBM_File->GDBM_version;

Returns the version number of the underlying B<libgdbm> library. In scalar
context, returns the library version formatted as string:

    MINOR.MAJOR[.PATCH][ (GUESS)]

where I<MINOR>, I<MAJOR>, and I<PATCH> are version numbers, and I<GUESS> is
a guess level (see below).

In list context, returns a list:

    ( MINOR, MAJOR, PATCH [, GUESS] )

The I<GUESS> component is present only if B<libgdbm> version is 1.8.3 or
earlier. This is because earlier releases of B<libgdbm> did not include
information about their version and the B<GDBM_File> module has to implement
certain guesswork in order to determine it. I<GUESS> is a textual description
in string context, and a positive number indicating how rough the guess is
in list context. Possible values are:

=over 4

=item 1  - exact guess

The major and minor version numbers are guaranteed to be correct. The actual
patchlevel is most probably guessed right, but can be 1-2 less than indicated.

=item 2  - approximate

The major and minor number are guaranteed to be correct. The patchlevel is
set to the upper bound.

=item 3  - rough guess

The version is guaranteed to be not newer than B<I<MAJOR>.I<MINOR>>.

=back

=head1 METHODS

=head2 close

    $db->close;

Closes the database. You are not advised to use this method directly. Please,
use B<untie> instead.

=head2 errno

    $db->errno

Returns the last error status associated with this database.

=head2 syserrno

    $db->syserrno

Returns the last system error status (C C<errno> variable), associated with
this database,

=head2 strerror

    $db->strerror

Returns textual description of the last error that occurred in this database.

=head2 clear_error

    $db->clear_error

Clear error status.

=head2 needs_recovery

    $db->needs_recovery

Returns true if the database needs recovery.

=head2 reorganize

    $db->reorganize;

Reorganizes the database.

=head2 sync

    $db->sync;

Synchronizes recent changes to the database with its disk copy.

=head2 count

    $n = $db->count;

Returns number of keys in the database.

=head2 flags

    $db->flags;

Returns flags passed as 4th argument to B<tie>.

=head2 dbname

    $db->dbname;

Returns the database name (i.e. 3rd argument to B<tie>.

=head2 cache_size

    $db->cache_size;
    $db->cache_size($newsize);

Returns the size of the internal B<GDBM> cache for that database.

Called with argument, sets the size to I<$newsize>.

=head2 block_size

    $db->block_size;

Returns the block size of the database.

=head2 sync_mode

    $db->sync_mode;
    $db->sync_mode($bool);

Returns the status of the automatic synchronization mode. Called with argument,
enables or disables the sync mode, depending on whether $bool is B<true> or
B<false>.

When synchronization mode is on (B<true>), any changes to the database are
immediately written to the disk. This ensures database consistency in case
of any unforeseen errors (e.g. power failures), at the expense of considerable
slowdown of operation.

Synchronization mode is off by default.

=head2 centfree

    $db->centfree;
    $db->centfree($bool);

Returns status of the central free block pool (B<0> - disabled,
B<1> - enabled).

With argument, changes its status.

By default, central free block pool is disabled.

=head2 coalesce

    $db->coalesce;
    $db->coalesce($bool);

=head2 mmap

    $db->mmap;

Returns true if memory mapping is enabled.

This method will B<croak> if the B<libgdbm> library is complied without
memory mapping support.

=head2 mmapsize

    $db->mmapsize;
    $db->mmapsize($newsize);

If memory mapping is enabled, returns the size of memory mapping. With
argument, sets the size to B<$newsize>.

This method will B<croak> if the B<libgdbm> library is complied without
memory mapping support.

=head2 recover

    $db->recover(%args);

Recovers data from a failed database. B<%args> is optional and can contain
following keys:

=over 4

=item err => sub { ... }

Reference to code for detailed error reporting. Upon encountering an error,
B<recover> will call this sub with a single argument - a description of the
error.

=item backup => \$str

Creates a backup copy of the database before recovery and returns its
filename in B<$str>.

=item max_failed_keys => $n

Maximum allowed number of failed keys. If the actual number becomes equal
to I<$n>, B<recover> aborts and returns error.

=item max_failed_buckets => $n

Maximum allowed number of failed buckets. If the actual number becomes equal
to I<$n>, B<recover> aborts and returns error.

=item max_failures => $n

Maximum allowed number of failures during recovery.

=item stat => \%hash

Return recovery statistics in I<%hash>. Upon return, the following keys will
be present:

=over 8

=item recovered_keys

Number of successfully recovered keys.

=item recovered_buckets

Number of successfully recovered buckets.

=item failed_keys

Number of keys that failed to be retrieved.

=item failed_buckets

Number of buckets that failed to be retrieved.

=back

=back


=head1 AVAILABILITY

gdbm is available from any GNU archive.  The master site is
C<ftp.gnu.org>, but you are strongly urged to use one of the many
mirrors.  You can obtain a list of mirror sites from
L<http://www.gnu.org/order/ftp.html>.

=head1 SECURITY AND PORTABILITY

B<Do not accept GDBM files from untrusted sources.>

GDBM files are not portable across platforms.

The GDBM documentation doesn't imply that files from untrusted sources
can be safely used with C<libgdbm>.

A maliciously crafted file might cause perl to crash or even expose a
security vulnerability.

=head1 SEE ALSO

L<perl(1)>, L<DB_File(3)>, L<perldbmfilter>,
L<gdbm(3)>,
L<https://www.gnu.org.ua/software/gdbm/manual.html>.

=cut

package GDBM_File;

use strict;
use warnings;
our($VERSION, @ISA, @EXPORT);

require Carp;
require Tie::Hash;
use Exporter 'import';
require XSLoader;
@ISA = qw(Tie::Hash);
@EXPORT = qw(
        GDBM_CACHESIZE
        GDBM_CENTFREE
        GDBM_COALESCEBLKS
        GDBM_FAST
        GDBM_FASTMODE
        GDBM_INSERT
        GDBM_NEWDB
        GDBM_NOLOCK
        GDBM_OPENMASK
        GDBM_READER
        GDBM_REPLACE
        GDBM_SYNC
        GDBM_SYNCMODE
        GDBM_WRCREAT
        GDBM_WRITER
);

# This module isn't dual life, so no need for dev version numbers.
$VERSION = '1.20';

XSLoader::load();

1;
