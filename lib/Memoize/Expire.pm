
package Memoize::Expire;
# require 5.00556;
use Carp;
$DEBUG = 0;
$VERSION = '0.51';

# This package will implement expiration by prepending a fixed-length header
# to the font of the cached data.  The format of the header will be:
# (4-byte number of last-access-time)  (For LRU when I implement it)
# (4-byte expiration time: unsigned seconds-since-unix-epoch)
# (2-byte number-of-uses-before-expire)

sub _header_fmt () { "N N n" }
sub _header_size () { length(_header_fmt) }

# Usage:  memoize func 
#         TIE => [Memoize::Expire, LIFETIME => sec, NUM_USES => n,
#                 TIE => [...] ]

sub TIEHASH {
  my ($package, %args) = @_;
  my %cache;
  if ($args{TIE}) {
    my ($module, @opts) = @{$args{TIE}};
    my $modulefile = $module . '.pm';
    $modulefile =~ s{::}{/}g;
    eval { require $modulefile };
    if ($@) {
      croak "Memoize::Expire: Couldn't load hash tie module `$module': $@; aborting";
    }
    my $rc = (tie %cache => $module, @opts);
    unless ($rc) {
      croak "Memoize::Expire: Couldn't tie hash to `$module': $@; aborting";
    }
  }
  $args{LIFETIME} ||= 0;
  $args{NUM_USES} ||= 0;
  $args{C} = \%cache;
  bless \%args => $package;
}

sub STORE {
  $DEBUG and print STDERR " >> Store $_[1] $_[2]\n";
  my ($self, $key, $value) = @_;
  my $expire_time = $self->{LIFETIME} > 0 ? $self->{LIFETIME} + time : 0;
  # The call that results in a value to store into the cache is the
  # first of the NUM_USES allowed calls.
  my $header = _make_header(time, $expire_time, $self->{NUM_USES}-1);
  $self->{C}{$key} = $header . $value;
  $value;
}

sub FETCH {
  $DEBUG and print STDERR " >> Fetch cached value for $_[1]\n";
  my ($data, $last_access, $expire_time, $num_uses_left) = _get_item($_[0]{C}{$_[1]});
  $DEBUG and print STDERR " >>   (ttl: ", ($expire_time-time), ", nuses: $num_uses_left)\n";
  $num_uses_left--;
  $last_access = time;
  _set_header(@_, $data, $last_access, $expire_time, $num_uses_left);
  $data;
}

sub EXISTS {
  $DEBUG and print STDERR " >> Exists $_[1]\n";
  unless (exists $_[0]{C}{$_[1]}) {
    $DEBUG and print STDERR "    Not in underlying hash at all.\n";
    return 0;
  }
  my $item = $_[0]{C}{$_[1]};
  my ($last_access, $expire_time, $num_uses_left) = _get_header($item);
  my $ttl = $expire_time - time;
  if ($DEBUG) {
    $_[0]{LIFETIME} and print STDERR "    Time to live for this item: $ttl\n";
    $_[0]{NUM_USES} and print STDERR "    Uses remaining: $num_uses_left\n";
  }
  if (   (! $_[0]{LIFETIME} || $expire_time > time)
      && (! $_[0]{NUM_USES} || $num_uses_left > 0 )) {
	    $DEBUG and print STDERR "    (Still good)\n";
    return 1;
  } else {
    $DEBUG and print STDERR "    (Expired)\n";
    return 0;
  }
}

# Arguments: last access time, expire time, number of uses remaining
sub _make_header {
  pack "N N n", @_;
}

sub _strip_header {
  substr($_[0], 10);
}

# Arguments: last access time, expire time, number of uses remaining
sub _set_header {
  my ($self, $key, $data, @header) = @_;
  $self->{C}{$key} = _make_header(@header) . $data;
}

sub _get_item {
  my $data = substr($_[0], 10);
  my @header = unpack "N N n", substr($_[0], 0, 10);
#  print STDERR " >> _get_item: $data => $data @header\n";
  ($data, @header);
}

# Return last access time, expire time, number of uses remaining
sub _get_header  {
  unpack "N N n", substr($_[0], 0, 10);
}

1;

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME 

Memoize::Expire - Plug-in module for automatic expiration of memoized values

=head1 SYNOPSIS

  use Memoize;
  memoize 'function',
    SCALAR_CACHE => [TIE, Memoize::Expire, 
	  	     LIFETIME => $lifetime,    # In seconds
		     NUM_USES => $n_uses,      
                     TIE      => [Module, args...],
		    ], 

=head1 DESCRIPTION

Memoize::Expire is a plug-in module for Memoize.  It allows the cached
values for memoized functions to expire automatically.  This manual
assumes you are already familiar with the Memoize module.  If not, you
should study that manual carefully first, paying particular attention
to the TIE feature.

Memoize::Expire is a layer of software that you can insert in between
Memoize itself and whatever underlying package implements the cache.
(By default, plain hash variables implement the cache.)  The layer
expires cached values whenever they get too old, have been used too
often, or both.

To specify a real-time timeout, supply the LIFETIME option with a
numeric value.  Cached data will expire after this many seconds, and
will be looked up afresh when it expires.  When a data item is looked
up afresh, its lifetime is reset.

If you specify NUM_USES with an argument of I<n>, then each cached
data item will be discarded and looked up afresh after the I<n>th time
you access it.  When a data item is looked up afresh, its number of
uses is reset.

If you specify both arguments, data will be discarded from the cache
when either expiration condition holds.  

If you want the cache to persist between invocations of your program,
supply a TIE option to specify the package name and arguments for a
the tied hash that will implement the persistence.  For example:

  use Memoize;
  use DB_File;
  memoize 'function',
    SCALAR_CACHE => [TIE, Memoize::Expire, 
	  	     LIFETIME => $lifetime,    # In seconds
		     NUM_USES => $n_uses,      
                     TIE      => [DB_File, $filename, O_CREAT|O_RDWR, 0666],
		    ], ...;



=head1 INTERFACE

There is nothing special about Memoize::Expire.  It is just an
example.  If you don't like the policy that it implements, you are
free to write your own expiration policy module that implements
whatever policy you desire.  Here is how to do that.  Let us suppose
that your module will be named MyExpirePolicy.

Short summary: You need to create a package that defines four methods:

=over 4

=item 
TIEHASH

Construct and return cache object.

=item 
EXISTS

Given a function argument, is the corresponding function value in the
cache, and if so, is it fresh enough to use?

=item
FETCH

Given a function argument, look up the corresponding function value in
the cache and return it.

=item 
STORE

Given a function argument and the corresponding function value, store
them into the cache.

=back

The user who wants the memoization cache to be expired according to
your policy will say so by writing

  memoize 'function',
    SCALAR_CACHE => [TIE, MyExpirePolicy, args...];

This will invoke MyExpirePolicy->TIEHASH(args).
MyExpirePolicy::TIEHASH should do whatever is appropriate to set up
the cache, and it should return the cache object to the caller.  

For example, MyExpirePolicy::TIEHASH might create an object that
contains a regular Perl hash (which it will to store the cached
values) and some extra information about the arguments and how old the
data is and things like that.  Let us call this object `C'.

When Memoize needs to check to see if an entry is in the cache
already, it will invoke C->EXISTS(key).  C<key> is the normalized
function argument.  MyExpirePolicy::EXISTS should return 0 if the key
is not in the cache, or if it has expired, and 1 if an unexpired value
is in the cache.  It should I<not> return C<undef>, because there is a
bug in some versions of Perl that will cause a spurious FETCH if the
EXISTS method returns C<undef>.

If your EXISTS function returns true, Memoize will try to fetch the
cached value by invoking C->FETCH(key).  MyExpirePolicy::FETCH should
return the cached value.  Otherwise, Memoize will call the memoized
function to compute the appropriate value, and will store it into the
cache by calling C->STORE(key, value).

Here is a very brief example of a policy module that expires each
cache item after ten seconds.

	package Memoize::TenSecondExpire;

	sub TIEHASH {
	  my ($package) = @_;
	  my %cache;
	  bless \%cache => $package;
	}

	sub EXISTS {
	  my ($cache, $key) = @_;
	  if (exists $cache->{$key} && 
              $cache->{$key}{EXPIRE_TIME} > time) {
	    return 1
	  } else {
	    return 0;  # Do NOT return `undef' here.
	  }
	}

	sub FETCH {
	  my ($cache, $key) = @_;
	  return $cache->{$key}{VALUE};
	}

	sub STORE {
	  my ($cache, $key, $newvalue) = @_;
	  $cache->{$key}{VALUE} = $newvalue;
	  $cache->{$key}{EXPIRE_TIME} = time + 10;
	}

To use this expiration policy, the user would say

	use Memoize;
	memoize 'function',
	    SCALAR_CACHE => [TIE, Memoize::TenSecondExpire];

Memoize would then call C<function> whenever a cached value was
entirely absent or was older than ten seconds.

It's nice if you allow a C<TIE> argument to C<TIEHASH> that ties the
underlying cache so that the user can specify that the cache is
persistent or that it has some other interesting semantics.  The
sample C<Memoize::Expire> module demonstrates how to do this.  It
implements a policy that expires cache items when they get too old or
when they have been accessed too many times.

Another sample module, C<Memoize::Saves>, is included with this
package.  It implements a policy that allows you to specify that
certain function values whould always be looked up afresh.  See the
documentation for details.

=head1 ALTERNATIVES

Joshua Chamas's Tie::Cache module may be useful as an expiration
manager.  (If you try this, let me know how it works out.)

If you develop any useful expiration managers that you think should be
distributed with Memoize, please let me know.

=head1 CAVEATS

This module is experimental, and may contain bugs.  Please report bugs
to the address below.

Number-of-uses is stored as a 16-bit unsigned integer, so can't exceed
65535.  

Because of clock granularity, expiration times may occur up to one
second sooner than you expect.  For example, suppose you store a value
with a lifetime of ten seconds, and you store it at 12:00:00.998 on a
certain day.  Memoize will look at the clock and see 12:00:00.  Then
9.01 seconds later, at 12:00:10.008 you try to read it back.  Memoize
will look at the clock and see 12:00:10 and conclude that the value
has expired.  Solution: Build an expiration policy module that uses
Time::HiRes to examine a clock with better granularity.  Contributions
are welcome.  Send them to:

=head1 AUTHOR

Mark-Jason Dominus (mjd-perl-memoize+@plover.com)

Mike Cariaso provided valuable insight into the best way to solve this
problem.  

=head1 SEE ALSO

perl(1)

The Memoize man page.

http://www.plover.com/~mjd/perl/Memoize/  (for news and updates)

I maintain a mailing list on which I occasionally announce new
versions of Memoize.  The list is for announcements only, not
discussion.  To join, send an empty message to
mjd-perl-memoize-request@Plover.com.  

=cut
