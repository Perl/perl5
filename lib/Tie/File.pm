
package Tie::File;
use Carp;
use POSIX 'SEEK_SET';
use Fcntl 'O_CREAT', 'O_RDWR', 'LOCK_EX';
require 5.005;

$VERSION = "0.15";

# Idea: The object will always contain an array of byte offsets
# this will be filled in as is necessary and convenient.
# fetch will do seek-read.
# There will be a cache parameter that controls the amount of cached *data*
# Also an LRU queue of cached records
# store will read the relevant record into the cache
# If it's the same length as what is being written, it will overwrite it in 
#   place; if not, it will do a from-to copying write.
# The record separator string is also a parameter

# Record numbers start at ZERO.

my $DEFAULT_CACHE_SIZE = 1<<21;    # 2 megabytes

sub TIEARRAY {
  if (@_ % 2 != 0) {
    croak "usage: tie \@array, $_[0], filename, [option => value]...";
  }
  my ($pack, $file, %opts) = @_;

  # transform '-foo' keys into 'foo' keys
  for my $key (keys %opts) {
    my $okey = $key;
    if ($key =~ s/^-+//) {
      $opts{$key} = delete $opts{$okey};
    }
  }

  $opts{cachesize} ||= $DEFAULT_CACHE_SIZE;

  # the cache is a hash instead of an array because it is likely to be
  # sparsely populated
  $opts{cache} = {}; 
  $opts{cached} = 0;   # total size of cached data
  $opts{lru} = [];     # replace with heap in later version

  $opts{offsets} = [0];
  $opts{filename} = $file;
  $opts{recsep} = $/ unless defined $opts{recsep};
  $opts{recseplen} = length($opts{recsep});
  if ($opts{recseplen} == 0) {
    croak "Empty record separator not supported by $pack";
  }

  my $mode = defined($opts{mode}) ? $opts{mode} : O_CREAT|O_RDWR;

  my $fh = \do { local *FH };   # only works in 5.005 and later
  sysopen $fh, $file, $mode, 0666 or return;
  binmode $fh;
  { my $ofh = select $fh; $| = 1; select $ofh } # autoflush on write
  $opts{fh} = $fh;

  bless \%opts => $pack;
}

sub FETCH {
  my ($self, $n) = @_;

  # check the record cache
  { my $cached = $self->_check_cache($n);
    return $cached if defined $cached;
  }

  unless ($#{$self->{offsets}} >= $n) {
    my $o = $self->_fill_offsets_to($n);
    # If it's still undefined, there is no such record, so return 'undef'
    return unless defined $o;
  }

  my $fh = $self->{FH};
  $self->_seek($n);             # we can do this now that offsets is populated
  my $rec = $self->_read_record;
  $self->_cache_insert($n, $rec) if defined $rec;
  $rec;
}

sub STORE {
  my ($self, $n, $rec) = @_;

  $self->_fixrecs($rec);

  # TODO: what should we do about the cache?  Install the new record
  # in the cache only if the old version of the same record was
  # already there?

  # We need this to decide whether the new record will fit
  # It incidentally populates the offsets table 
  # Note we have to do this before we alter the cache
  my $oldrec = $self->FETCH($n);

  # _check_cache promotes record $n to MRU.  Is this correct behavior?
  $self->{cache}{$n} = $rec if $self->_check_cache($n);

  if (not defined $oldrec) {
    # We're storing a record beyond the end of the file
    $self->_extend_file_to($n+1);
    $oldrec = $self->{recsep};
  }
  my $len_diff = length($rec) - length($oldrec);

  $self->_twrite($rec, $self->{offsets}[$n], length($oldrec));

  # now update the offsets
  # array slice goes from element $n+1 (the first one to move)
  # to the end
  for (@{$self->{offsets}}[$n+1 .. $#{$self->{offsets}}]) {
    $_ += $len_diff;
  }
}

sub FETCHSIZE {
  my $self = shift;
  my $n = $#{$self->{offsets}};
  while (defined ($self->_fill_offsets_to($n+1))) {
    ++$n;
  }
  $n;
}

sub STORESIZE {
  my ($self, $len) = @_;
  my $olen = $self->FETCHSIZE;
  return if $len == $olen;      # Woo-hoo!

  # file gets longer
  if ($len > $olen) {
    $self->_extend_file_to($len);
    return;
  }

  # file gets shorter
  $self->_seek($len);
  $self->_chop_file;
  $#{$self->{offsets}} = $len-1;
  my @cached = grep $_ > $len, keys %{$self->{cache}};
  delete @{$self->{cache}}{@cached} if @cached;
}

sub PUSH {
  my $self = shift;
  $self->SPLICE($self->FETCHSIZE, scalar(@_), @_);
  $self->FETCHSIZE;
}

sub POP {
  my $self = shift;
  my $size = $self->FETCHSIZE;
  return if $size == 0;
#  print STDERR "# POPPITY POP POP POP\n";
  scalar $self->SPLICE($size-1, 1);
}

sub SHIFT {
  my $self = shift;
  scalar $self->SPLICE(0, 1);
}

sub UNSHIFT {
  my $self = shift;
  $self->SPLICE(0, 0, @_);
  $self->FETCHSIZE;
}

sub CLEAR {
  # And enable auto-defer mode, since it's likely that they just
  # did @a = (...);
  my $self = shift;
  $self->_seekb(0);
  $self->_chop_file;
  %{$self->{cache}}   = ();
    $self->{cached}   = 0;
  @{$self->{lru}}     = ();
  @{$self->{offsets}} = (0);
}

sub EXTEND {
  my ($self, $n) = @_;
  $self->_fill_offsets_to($n);
  $self->_extend_file_to($n);
}

sub DELETE {
  my ($self, $n) = @_;
  my $lastrec = $self->FETCHSIZE-1;
  if ($n == $lastrec) {
    $self->_seek($n);
    $self->_chop_file;
    # perhaps in this case I should also remove trailing null records?
  } else {
    $self->STORE($n, "");
  }
}

sub EXISTS {
  my ($self, $n) = @_;
  $self->_fill_offsets_to($n);
  0 <= $n && $n < $self->FETCHSIZE;
}

sub SPLICE {
  my ($self, $pos, $nrecs, @data) = @_;
  my @result;

  $pos = 0 unless defined $pos;

  # Deal with negative and other out-of-range positions
  # Also set default for $nrecs 
  {
    my $oldsize = $self->FETCHSIZE;
    $nrecs = $oldsize unless defined $nrecs;
    my $oldpos = $pos;

    if ($pos < 0) {
      $pos += $oldsize;
      if ($pos < 0) {
        croak "Modification of non-creatable array value attempted, subscript $oldpos";
      }
    }

    if ($pos > $oldsize) {
      return unless @data;
      $pos = $oldsize;          # This is what perl does for normal arrays
    }
  }

  $self->_fixrecs(@data);
  my $data = join '', @data;
  my $datalen = length $data;
  my $oldlen = 0;

  # compute length of data being removed
  # Incidentally fills offsets table
  for ($pos .. $pos+$nrecs-1) {
    my $rec = $self->FETCH($_);
    last unless defined $rec;
    push @result, $rec;
    $oldlen += length($rec);
  }

  # Modify the file
  $self->_twrite($data, $self->{offsets}[$pos], $oldlen);

  # update the offsets table part 1
  # compute the offsets of the new records:
  my @new_offsets;
  if (@data) {
    push @new_offsets, $self->{offsets}[$pos];
    for (0 .. $#data-1) {
      push @new_offsets, $new_offsets[-1] + length($data[$_]);
    }
  }
  splice(@{$self->{offsets}}, $pos, $nrecs, @new_offsets);

  # update the offsets table part 2
  # adjust the offsets of the following old records
  for ($pos+@data .. $#{$self->{offsets}}) {
    $self->{offsets}[$_] += $datalen - $oldlen;
  }
  # If we scrubbed out all known offsets, regenerate the trivial table
  # that knows that the file does indeed start at 0.
  $self->{offsets}[0] = 0 unless @{$self->{offsets}};

  # Perhaps the following cache foolery could be factored out
  # into a bunch of mor opaque cache functions.  For example,
  # it's odd to delete a record from the cache and then remove
  # it from the LRU queue later on; there should be a function to
  # do both at once.

  # update the read cache, part 1
  # modified records
  # Consider this carefully for correctness
  for ($pos .. $pos+$nrecs-1) {
    my $cached = $self->{cache}{$_};
    next unless defined $cached;
    my $new = $data[$_-$pos];
    if (defined $new) {
      $self->{cached} += length($new) - length($cached);
      $self->{cache}{$_} = $new;
    } else {
      delete $self->{cache}{$_};
      $self->{cached} -= length($cached);
    }
  }
  # update the read cache, part 2
  # moved records - records past the site of the change
  # need to be renumbered
  # Maybe merge this with the previous block?
  for (keys %{$self->{cache}}) {
    next unless $_ >= $pos + $nrecs;
    $self->{cache}{$_-$nrecs+@data} = delete $self->{cache}{$_};
  }

  # fix the LRU queue
  my(@new, @changed);
  for (@{$self->{lru}}) {
    if ($_ >= $pos + $nrecs) {
      push @new, $_ + @data - $nrecs;
    } elsif ($_ >= $pos) {
      push @changed, $_ if $_ < $pos + @data;
    } else {
      push @new, $_;
    }
  }
  @{$self->{lru}} = (@new, @changed);

  # Yes, the return value of 'splice' *is* actually this complicated
  wantarray ? @result : @result ? $result[-1] : undef;
}

# write data into the file
# $data is the data to be written. 
# it should be written at position $pos, and should overwrite
# exactly $len of the following bytes.  
# Note that if length($data) > $len, the subsequent bytes will have to 
# be moved up, and if length($data) < $len, they will have to
# be moved down
sub _twrite {
  my ($self, $data, $pos, $len) = @_;

  unless (defined $pos) {
    die "\$pos was undefined in _twrite";
  }

  my $len_diff = length($data) - $len;

  if ($len_diff == 0) {          # Woo-hoo!
    my $fh = $self->{fh};
    $self->_seekb($pos);
    $self->_write_record($data);
    return;                     # well, that was easy.
  }

  # the two records are of different lengths
  # our strategy here: rewrite the tail of the file,
  # reading ahead one buffer at a time
  # $bufsize is required to be at least as large as the data we're overwriting
  my $bufsize = _bufsize($len_diff);
  my ($writepos, $readpos) = ($pos, $pos+$len);
  my $next_block;

  # Seems like there ought to be a way to avoid the repeated code
  # and the special case here.  The read(1) is also a little weird.
  # Think about this.
  do {
    $self->_seekb($readpos);
    my $br = read $self->{fh}, $next_block, $bufsize;
    my $more_data = read $self->{fh}, my($dummy), 1;
    $self->_seekb($writepos);
    $self->_write_record($data);
    $readpos += $br;
    $writepos += length $data;
    $data = $next_block;
  } while $more_data;
  $self->_seekb($writepos);
  $self->_write_record($next_block);

  # There might be leftover data at the end of the file
  $self->_chop_file if $len_diff < 0;
}

# If a record does not already end with the appropriate terminator
# string, append one.
sub _fixrecs {
  my $self = shift;
  for (@_) {
    $_ .= $self->{recsep}
      unless substr($_, - $self->{recseplen}) eq $self->{recsep};
  }
}

# seek to the beginning of record #$n
# Assumes that the offsets table is already correctly populated
#
# Note that $n=-1 has a special meaning here: It means the start of
# the last known record; this may or may not be the very last record
# in the file, depending on whether the offsets table is fully populated.
#
sub _seek {
  my ($self, $n) = @_;
  my $o = $self->{offsets}[$n];
  defined($o)
    or confess("logic error: undefined offset for record $n");
  seek $self->{fh}, $o, SEEK_SET
    or die "Couldn't seek filehandle: $!";  # "Should never happen."
}

sub _seekb {
  my ($self, $b) = @_;
  seek $self->{fh}, $b, SEEK_SET
    or die "Couldn't seek filehandle: $!";  # "Should never happen."
}

# populate the offsets table up to the beginning of record $n
# return the offset of record $n
sub _fill_offsets_to {
  my ($self, $n) = @_;
  my $fh = $self->{fh};
  local *OFF = $self->{offsets};
  my $rec;

  until ($#OFF >= $n) {
    my $o = $OFF[-1];
    $self->_seek(-1);           # tricky -- see comment at _seek
    $rec = $self->_read_record;
    if (defined $rec) {
      push @OFF, tell $fh;
    } else {
      return;                   # It turns out there is no such record
    }
  }

  # we have now read all the records up to record n-1,
  # so we can return the offset of record n
  return $OFF[$n];
}

# assumes that $rec is already suitably terminated
sub _write_record {
  my ($self, $rec) = @_;
  my $fh = $self->{fh};
  print $fh $rec
    or die "Couldn't write record: $!";  # "Should never happen."

}

sub _read_record {
  my $self = shift;
  my $rec;
  { local $/ = $self->{recsep};
    my $fh = $self->{fh};
    $rec = <$fh>;
  }
  $rec;
}

sub _cache_insert {
  my ($self, $n, $rec) = @_;

  # Do not cache records that are too big to fit in the cache.
  return unless length $rec <= $self->{cachesize};

  $self->{cache}{$n} = $rec;
  $self->{cached} += length $rec;
  push @{$self->{lru}}, $n;     # most-recently-used is at the END

  $self->_cache_flush if $self->{cached} > $self->{cachesize};
}

sub _check_cache {
  my ($self, $n) = @_;
  my $rec;
  return unless defined($rec = $self->{cache}{$n});

  # cache hit; update LRU queue and return $rec
  # replace this with a heap in a later version
  @{$self->{lru}} = ((grep $_ ne $n, @{$self->{lru}}), $n);
  $rec;
}

sub _cache_flush {
  my ($self) = @_;
  while ($self->{cached} > $self->{cachesize}) {
    my $lru = shift @{$self->{lru}};
    $self->{cached} -= length $lru;
    delete $self->{cache}{$lru};
  }
}

# We have read to the end of the file and have the offsets table
# entirely populated.  Now we need to write a new record beyond
# the end of the file.  We prepare for this by writing
# empty records into the file up to the position we want
#
# assumes that the offsets table already contains the offset of record $n,
# if it exists, and extends to the end of the file if not.
sub _extend_file_to {
  my ($self, $n) = @_;
  $self->_seek(-1);             # position after the end of the last record
  my $pos = $self->{offsets}[-1];

  # the offsets table has one entry more than the total number of records
  $extras = $n - $#{$self->{offsets}};

  # Todo : just use $self->{recsep} x $extras here?
  while ($extras-- > 0) {
    $self->_write_record($self->{recsep});
    $pos += $self->{recseplen};
    push @{$self->{offsets}}, $pos;
  }
}

# Truncate the file at the current position
sub _chop_file {
  my $self = shift;
  truncate $self->{fh}, tell($self->{fh});
}

# compute the size of a buffer suitable for moving
# all the data in a file forward $n bytes
# ($n may be negative)
# The result should be at least $n.
sub _bufsize {
  my $n = shift;
  return 8192 if $n < 0;
  my $b = $n & ~8191;
  $b += 8192 if $n & 8191;
  $b;
}

# Lock the file
sub flock {
  my ($self, $op) = @_;
  unless (@_ <= 3) {
    my $pack = ref $self;
    croak "Usage: $pack\->flock([OPERATION])";
  }
  my $fh = $self->{fh};
  $op = LOCK_EX unless defined $op;
  flock $fh, $op;
}

# Given a file, make sure the cache is consistent with the
# file contents
sub _check_integrity {
  my ($self, $file, $warn) = @_;
  my $good = 1; 
  local *F = $self->{fh};
  seek F, 0, SEEK_SET;
#  open F, $file or die "Couldn't open file $file: $!";
#  binmode F;
  local $/ = $self->{recsep};
  unless ($self->{offsets}[0] == 0) {
    $warn && print STDERR "# rec 0: offset <$self->{offsets}[0]> s/b 0!\n";
    $good = 0;
  }
  while (<F>) {
    my $n = $. - 1;
    my $cached = $self->{cache}{$n};
    my $offset = $self->{offsets}[$.];
    my $ao = tell F;
    if (defined $offset && $offset != $ao) {
      $warn && print STDERR "# rec $n: offset <$offset> actual <$ao>\n";
    }
    if (defined $cached && $_ ne $cached) {
      $good = 0;
      chomp $cached;
      chomp;
      $warn && print STDERR "# rec $n: cached <$cached> actual <$_>\n";
    }
  }

  my $cachesize = 0;
  while (my ($n, $r) = each %{$self->{cache}}) {
    $cachesize += length($r);
    next if $n+1 <= $.;         # checked this already
    $warn && print STDERR "# spurious caching of record $n\n";
    $good = 0;
  }
  if ($cachesize != $self->{cached}) {
    $warn && print STDERR "# cache size is $self->{cached}, should be $cachesize\n";
    $good = 0;
  }

  my (%seen, @duplicate);
  for (@{$self->{lru}}) {
    $seen{$_}++;
    if (not exists $self->{cache}{$_}) {
      print "# $_ is mentioned in the LRU queue, but not in the cache\n";
      $good = 0;
    }
  }
  @duplicate = grep $seen{$_}>1, keys %seen;
  if (@duplicate) {
    my $records = @duplicate == 1 ? 'Record' : 'Records';
    my $appear  = @duplicate == 1 ? 'appears' : 'appear';
    print "# $records @duplicate $appear multiple times in LRU queue: @{$self->{lru}}\n";
    $good = 0;
  }
  for (keys %{$self->{cache}}) {
    unless (exists $seen{$_}) {
      print "# $record $_ is in the cache but not the LRU queue\n";
      $good = 0;
    }
  }

  $good;
}

=head1 NAME

Tie::File - Access the lines of a disk file via a Perl array

=head1 SYNOPSIS

	# This file documents Tie::File version 0.15

	tie @array, 'Tie::File', filename or die ...;

	$array[13] = 'blah';     # line 13 of the file is now 'blah'
	print $array[42];        # display line 42 of the file

	$n_recs = @array;        # how many records are in the file?
	$#array = $n_recs - 2;   # chop records off the end

	# As you would expect:

	push @array, new recs...;
	my $r1 = pop @array;
	unshift @array, new recs...;
	my $r1 = shift @array;
	@old_recs = splice @array, 3, 7, new recs...;

	untie @array;            # all finished

=head1 DESCRIPTION

C<Tie::File> represents a regular text file as a Perl array.  Each
element in the array corresponds to a record in the file.  The first
line of the file is element 0 of the array; the second line is element
1, and so on.

The file is I<not> loaded into memory, so this will work even for
gigantic files.

Changes to the array are reflected in the file immediately.

=head2 C<recsep>

What is a 'record'?  By default, the meaning is the same as for the
C<E<lt>...E<gt>> operator: It's a string terminated by C<$/>, which is
probably C<"\n"> or C<"\r\n">.  You may change the definition of
"record" by supplying the C<recsep> option in the C<tie> call:

	tie @array, 'Tie::File', $file, recsep => 'es';

This says that records are delimited by the string C<es>.  If the file contained the following data:

	Curse these pesky flies!\n

then the C<@array> would appear to have four elements: 

	"Curse thes"
	"e pes"
	"ky flies"
	"!\n"

An undefined value is not permitted as a record separator.  Perl's
special "paragraph mode" semantics (E<agrave> la C<$/ = "">) are not
emulated.

Records read from the tied array will have the record separator string
on the end, just as if they were read from the C<E<lt>...E<gt>>
operator.  Records stored into the array will have the record
separator string appended before they are written to the file, if they
don't have one already.  For example, if the record separator string
is C<"\n">, then the following two lines do exactly the same thing:

	$array[17] = "Cherry pie";
	$array[17] = "Cherry pie\n";

The result is that the contents of line 17 of the file will be
replaced with "Cherry pie"; a newline character will separate line 17
from line 18.  This means that in particular, this will do nothing:

	chomp $array[17];

Because the C<chomp>ed value will have the separator reattached when
it is written back to the file.  There is no way to create a file
whose trailing record separator string is missing.

Inserting records that I<contain> the record separator string will
produce a reasonable result, but if you can't foresee what this result
will be, you'd better avoid doing this.

=head2 C<mode>

Normally, the specified file will be opened for read and write access,
and will be created if it does not exist.  (That is, the flags
C<O_RDWR | O_CREAT> are supplied in the C<open> call.)  If you want to
change this, you may supply alternative flags in the C<mode> option.
See L<Fcntl> for a listing of available flags.
For example:

	# open the file if it exists, but fail if it does not exist
	use Fcntl 'O_RDWR';
	tie @array, 'Tie::File', $file, mode => O_RDWR;

	# create the file if it does not exist
	use Fcntl 'O_RDWR', 'O_CREAT';
	tie @array, 'Tie::File', $file, mode => O_RDWR | O_CREAT;

	# open an existing file in read-only mode
	use Fcntl 'O_RDONLY';
	tie @array, 'Tie::File', $file, mode => O_RDONLY;

Opening the data file in write-only or append mode is not supported.

=head2 C<cachesize>

Records read in from the file are cached, to avoid having to re-read
them repeatedly.  If you read the same record twice, the first time it
will be stored in memory, and the second time it will be fetched from
memory.

The cache has a bounded size; when it exceeds this size, the
least-recently visited records will be purged from the cache.  The
default size is 2Mib.  You can adjust the amount of space used for the
cache by supplying the C<cachesize> option.  The argument is the desired cache size, in bytes.

	# I have a lot of memory, so use a large cache to speed up access
	tie @array, 'Tie::File', $file, cachesize => 20_000_000;

Setting the cache size to 0 will inhibit caching; records will be
fetched from disk every time you examine them.

=head2 Option Format

C<-mode> is a synonym for C<mode>.  C<-recsep> is a synonym for
C<recsep>.  C<-cachesize> is a synonym for C<cachesize>.  You get the
idea.

=head1 Public Methods

The C<tie> call returns an object, say C<$o>.  You may call 

	$rec = $o->FETCH($n);
	$o->STORE($n, $rec);

to fetch or store the record at line C<$n>, respectively.  The only other public method in this package is:

=head2 C<flock>

	$o->flock(MODE)

will lock the tied file.  C<MODE> has the same meaning as the second
argument to the Perl built-in C<flock> function; for example
C<LOCK_SH> or C<LOCK_EX | LOCK_NB>.  (These constants are provided by
the C<use Fcntl ':flock'> declaration.)

C<MODE> is optional; C<< $o->flock >> simply locks the file with
C<LOCK_EX>.

The best way to unlock a file is to discard the object and untie the
array.  It is probably unsafe to unlock the file without also untying
it, because if you do, changes may remain unwritten inside the object.
That is why there is no shortcut for unlocking.  If you really want to
unlock the file prematurely, you know what to do; if you don't know
what to do, then don't do it.

All the usual warnings about file locking apply here.  In particular,
note that file locking in Perl is B<advisory>, which means that
holding a lock will not prevent anyone else from reading, writing, or
erasing the file; it only prevents them from getting another lock at
the same time.  Locks are analogous to green traffic lights: If you
have a green light, that does not prevent the idiot coming the other
way from plowing into you sideways; it merely guarantees to you that
the idiot does not also have a green light at the same time.

=head1 CAVEATS

(That's Latin for 'warnings'.)

=head2 Efficiency Note

Every effort was made to make this module efficient.  Nevertheless,
changing the size of a record in the middle of a large file will
always be slow, because everything after the new record must be move.

In particular, note that:

	# million-line file
	for (@file_array) {
	  $_ .= 'x';
	}

is likely to be very slow, because the first iteration must relocate
lines 1 through 999,999; the second iteration must relocate lines 2
through 999,999, and so on.  The relocation is done using block
writes, however, so it's not as slow as it might be.

A future version of this module will provide a mechanism for getting
better performance in such cases, by deferring the writing until it
can be done all at once.

=head2 Efficiency Note 2

Not every effort was made to make this module as efficient as
possible.  C<FETCHSIZE> should use binary search instead of linear
search.  The cache's LRU queue should be a heap instead of a list.
These defects are probably minor; in any event, they will be fixed in
a later version of the module.

=head2 Efficiency Note 3

The author has supposed that since this module is concerned with file
I/O, almost all normal use of it will be heavily I/O bound, and that
the time to maintain complicated data structures inside the module
will be dominated by the time to actually perform the I/O.  This
suggests, for example, that and LRU read-cache is a good tradeoff,
even if it requires substantial adjustment following a C<splice>
operation.

=head1 CAVEATS

(That's Latin for 'warnings'.)

The behavior of tied arrays is not precisely the same as for regular
arrays.  For example:

	undef $a[10];  print "How unusual!\n" if $a[10];

C<undef>-ing a C<Tie::File> array element just blanks out the
corresponding record in the file.  When you read it back again, you'll
see the record separator (typically, $a[10] will appear to contain
"\n") so the supposedly-C<undef>'ed value will be true.

There are other minor differences, but in general, the correspondence
is extremely close.

=head1 AUTHOR

Mark Jason Dominus

To contact the author, send email to: C<mjd-perl-tiefile+@plover.com>

To receive an announcement whenever a new version of this module is
released, send a blank email message to
C<mjd-perl-tiefile-subscribe@plover.com>.

=head1 LICENSE

C<Tie::File> version 0.15 is copyright (C) 2002 Mark Jason Dominus.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

These terms include your choice of (1) the Perl Artistic Licence, or
(2) version 2 of the GNU General Public License as published by the
Free Software Foundation, or (3) any later version of the GNU General
Public License.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library program; it should be in the file C<COPYING>.
If not, write to the Free Software Foundation, Inc., 59 Temple Place,
Suite 330, Boston, MA 02111 USA

For licensing inquiries, contact the author at:

	Mark Jason Dominus
	255 S. Warnock St.
	Philadelphia, PA 19107

=head1 WARRANTY

C<Tie::File> version 0.15 comes with ABSOLUTELY NO WARRANTY.
For details, see the license.

=head1 TODO

Allow tie to seekable filehandle rather than named file.

Tests for default arguments to SPLICE.  Tests for CLEAR/EXTEND.
Tests for DELETE/EXISTS.

More tests.  (Configuration options, cache flushery, locking.  _twrite
should be tested separately, because there are a lot of weird special
cases lurking in there.)

More tests.  (Stuff I didn't think of yet.)

Deferred writing. (!!!)

Paragraph mode?

More tests.

Fixed-length mode.

=cut

