# DB_File.pm -- Perl 5 interface to Berkeley DB 
#
# written by Paul Marquess (pmarquess@bfsec.bt.co.uk)
# last modified 28th June 1996
# version 1.02

package DB_File::HASHINFO ;

use strict;
use Carp;
require Tie::Hash;
@DB_File::HASHINFO::ISA = qw(Tie::Hash);

sub new
{
    my $pkg = shift ;
    my %x ;
    tie %x, $pkg ;
    bless \%x, $pkg ;
}

sub TIEHASH
{
    my $pkg = shift ;

    bless {   'bsize'     => undef,
              'ffactor'   => undef,
              'nelem'     => undef,
              'cachesize' => undef,
              'hash'      => undef,
              'lorder'    => undef,
        }, $pkg ;
}

sub FETCH 
{  
    my $self  = shift ;
    my $key   = shift ;

    return $self->{$key} if exists $self->{$key}  ;

    my $pkg = ref $self ;
    croak "${pkg}::FETCH - Unknown element '$key'" ;
}


sub STORE 
{
    my $self  = shift ;
    my $key   = shift ;
    my $value = shift ;

    if ( exists $self->{$key} )
    {
        $self->{$key} = $value ;
        return ;
    }
    
    my $pkg = ref $self ;
    croak "${pkg}::STORE - Unknown element '$key'" ;
}

sub DELETE 
{
    my $self = shift ;
    my $key  = shift ;

    if ( exists $self->{$key} )
    {
        delete $self->{$key} ;
        return ;
    }
    
    my $pkg = ref $self ;
    croak "DB_File::HASHINFO::DELETE - Unknown element '$key'" ;
}

sub EXISTS
{
    my $self = shift ;
    my $key  = shift ;

    exists $self->{$key} ;
}

sub NotHere
{
    my $pkg = shift ;
    my $method = shift ;

    croak "${pkg} does not define the method ${method}" ;
}

sub DESTROY  { undef %{$_[0]} }
sub FIRSTKEY { my $self = shift ; $self->NotHere(ref $self, "FIRSTKEY") }
sub NEXTKEY  { my $self = shift ; $self->NotHere(ref $self, "NEXTKEY") }
sub CLEAR    { my $self = shift ; $self->NotHere(ref $self, "CLEAR") }

package DB_File::RECNOINFO ;

use strict ;

@DB_File::RECNOINFO::ISA = qw(DB_File::HASHINFO) ;

sub TIEHASH
{
    my $pkg = shift ;

    bless {   'bval'      => undef,
              'cachesize' => undef,
              'psize'     => undef,
              'flags'     => undef,
              'lorder'    => undef,
              'reclen'    => undef,
              'bfname'    => "",
            }, $pkg ;
}

package DB_File::BTREEINFO ;

use strict ;

@DB_File::BTREEINFO::ISA = qw(DB_File::HASHINFO) ;

sub TIEHASH
{
    my $pkg = shift ;

    bless {   'flags'	   => undef,
              'cachesize'  => undef,
              'maxkeypage' => undef,
              'minkeypage' => undef,
              'psize'      => undef,
              'compare'    => undef,
              'prefix'     => undef,
              'lorder'     => undef,
            }, $pkg ;
}


package DB_File ;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD $DB_BTREE $DB_HASH $DB_RECNO) ;
use Carp;


$VERSION = "1.02" ;

#typedef enum { DB_BTREE, DB_HASH, DB_RECNO } DBTYPE;
#$DB_BTREE = TIEHASH DB_File::BTREEINFO ;
#$DB_HASH  = TIEHASH DB_File::HASHINFO ;
#$DB_RECNO = TIEHASH DB_File::RECNOINFO ;

$DB_BTREE = new DB_File::BTREEINFO ;
$DB_HASH  = new DB_File::HASHINFO ;
$DB_RECNO = new DB_File::RECNOINFO ;

require Tie::Hash;
require Exporter;
use AutoLoader;
require DynaLoader;
@ISA = qw(Tie::Hash Exporter DynaLoader);
@EXPORT = qw(
        $DB_BTREE $DB_HASH $DB_RECNO 

	BTREEMAGIC
	BTREEVERSION
	DB_LOCK
	DB_SHMEM
	DB_TXN
	HASHMAGIC
	HASHVERSION
	MAX_PAGE_NUMBER
	MAX_PAGE_OFFSET
	MAX_REC_NUMBER
	RET_ERROR
	RET_SPECIAL
	RET_SUCCESS
	R_CURSOR
	R_DUP
	R_FIRST
	R_FIXEDLEN
	R_IAFTER
	R_IBEFORE
	R_LAST
	R_NEXT
	R_NOKEY
	R_NOOVERWRITE
	R_PREV
	R_RECNOSYNC
	R_SETCURSOR
	R_SNAPSHOT
	__R_UNUSED

);

sub AUTOLOAD {
    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    my($pack,$file,$line) = caller;
	    croak "Your vendor has not defined DB macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DB_File $VERSION;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.


sub get_dup
{
    croak "Usage: \$db->get_dup(key [,flag])\n"
        unless @_ == 2 or @_ == 3 ;
 
    my $db        = shift ;
    my $key       = shift ;
    my $flag	  = shift ;
    my $value ;
    my $origkey   = $key ;
    my $wantarray = wantarray ;
    my @values    = () ;
    my $counter   = 0 ;
 
    # get the first value associated with the key, $key
    $db->seq($key, $value, R_CURSOR()) ;
 
    if ( $key eq $origkey) {
 
        while (1) {
            # save the value or count matches
            if ($wantarray)
                { push (@values, $value) ; push(@values, 1) if $flag }
            else
                { ++ $counter }
     
            # iterate through the database until either EOF 
            # or a different key is encountered.
            last if $db->seq($key, $value, R_NEXT()) != 0 or $key ne $origkey ;
        }
    }
 
    $wantarray ? @values : $counter ;
}


1;
__END__

=cut

=head1 NAME

DB_File - Perl5 access to Berkeley DB

=head1 SYNOPSIS

 use DB_File ;
 use Fcntl ;
 
 [$X =] tie %hash,  'DB_File', [$filename, $flags, $mode, $DB_HASH] ;
 [$X =] tie %hash,  'DB_File', $filename, $flags, $mode, $DB_BTREE ;
 [$X =] tie @array, 'DB_File', $filename, $flags, $mode, $DB_RECNO ;
  
 [$X =] tie %hash,  DB_File, $filename [, $flags, $mode, $DB_HASH ] ;
 [$X =] tie %hash,  DB_File, $filename, $flags, $mode, $DB_BTREE ;
 [$X =] tie @array, DB_File, $filename, $flags, $mode, $DB_RECNO ;
   
 $status = $X->del($key [, $flags]) ;
 $status = $X->put($key, $value [, $flags]) ;
 $status = $X->get($key, $value [, $flags]) ;
 $status = $X->seq($key, $value , $flags) ;
 $status = $X->sync([$flags]) ;
 $status = $X->fd ;
    
 $count = $X->get_dup($key) ;
 @list  = $X->get_dup($key) ;
 %list  = $X->get_dup($key, 1) ;

 untie %hash ;
 untie @array ;

=head1 DESCRIPTION

B<DB_File> is a module which allows Perl programs to make use of the
facilities provided by Berkeley DB.  If you intend to use this
module you should really have a copy of the Berkeley DB manual page at
hand. The interface defined here mirrors the Berkeley DB interface
closely.

Berkeley DB is a C library which provides a consistent interface to a
number of database formats.  B<DB_File> provides an interface to all
three of the database types currently supported by Berkeley DB.

The file types are:

=over 5

=item B<DB_HASH>

This database type allows arbitrary key/value pairs to be stored in data
files. This is equivalent to the functionality provided by other
hashing packages like DBM, NDBM, ODBM, GDBM, and SDBM. Remember though,
the files created using DB_HASH are not compatible with any of the
other packages mentioned.

A default hashing algorithm, which will be adequate for most
applications, is built into Berkeley DB. If you do need to use your own
hashing algorithm it is possible to write your own in Perl and have
B<DB_File> use it instead.

When opening an existing database, you may omit the final three arguments
to C<tie>; they default to O_RDWR, 0644, and $DB_HASH.  If you're
creating a new file, you need to specify at least the C<$flags>
argument, which must include O_CREAT.

=item B<DB_BTREE>

The btree format allows arbitrary key/value pairs to be stored in a
sorted, balanced binary tree.

As with the DB_HASH format, it is possible to provide a user defined
Perl routine to perform the comparison of keys. By default, though, the
keys are stored in lexical order.

=item B<DB_RECNO>

DB_RECNO allows both fixed-length and variable-length flat text files
to be manipulated using the same key/value pair interface as in DB_HASH
and DB_BTREE.  In this case the key will consist of a record (line)
number.

=back

=head2 How does DB_File interface to Berkeley DB?

B<DB_File> allows access to Berkeley DB files using the tie() mechanism
in Perl 5 (for full details, see L<perlfunc/tie()>). This facility
allows B<DB_File> to access Berkeley DB files using either an
associative array (for DB_HASH & DB_BTREE file types) or an ordinary
array (for the DB_RECNO file type).

In addition to the tie() interface, it is also possible to access most
of the functions provided in the Berkeley DB API directly.
See L<"Using the Berkeley DB API Directly">.

=head2 Opening a Berkeley DB Database File

Berkeley DB uses the function dbopen() to open or create a database.
Below is the C prototype for dbopen().

      DB*
      dbopen (const char * file, int flags, int mode, 
              DBTYPE type, const void * openinfo)

The parameter C<type> is an enumeration which specifies which of the 3
interface methods (DB_HASH, DB_BTREE or DB_RECNO) is to be used.
Depending on which of these is actually chosen, the final parameter,
I<openinfo> points to a data structure which allows tailoring of the
specific interface method.

This interface is handled slightly differently in B<DB_File>. Here is
an equivalent call using B<DB_File>:

        tie %array, 'DB_File', $filename, $flags, $mode, $DB_HASH ;

The C<filename>, C<flags> and C<mode> parameters are the direct
equivalent of their dbopen() counterparts. The final parameter $DB_HASH
performs the function of both the C<type> and C<openinfo> parameters in
dbopen().

In the example above $DB_HASH is actually a pre-defined reference to a
hash object. B<DB_File> has three of these pre-defined references.
Apart from $DB_HASH, there is also $DB_BTREE and $DB_RECNO.

The keys allowed in each of these pre-defined references is limited to
the names used in the equivalent C structure. So, for example, the
$DB_HASH reference will only allow keys called C<bsize>, C<cachesize>,
C<ffactor>, C<hash>, C<lorder> and C<nelem>. 

To change one of these elements, just assign to it like this:

	$DB_HASH->{'cachesize'} = 10000 ;

The three predefined variables $DB_HASH, $DB_BTREE and $DB_RECNO are
usually adequate for most applications.  If you do need to create extra
instances of these objects, constructors are available for each file
type.

Here are examples of the constructors and the valid options available
for DB_HASH, DB_BTREE and DB_RECNO respectively.

     $a = new DB_File::HASHINFO ;
     $a->{'bsize'} ;
     $a->{'cachesize'} ;
     $a->{'ffactor'};
     $a->{'hash'} ;
     $a->{'lorder'} ;
     $a->{'nelem'} ;

     $b = new DB_File::BTREEINFO ;
     $b->{'flags'} ;
     $b->{'cachesize'} ;
     $b->{'maxkeypage'} ;
     $b->{'minkeypage'} ;
     $b->{'psize'} ;
     $b->{'compare'} ;
     $b->{'prefix'} ;
     $b->{'lorder'} ;

     $c = new DB_File::RECNOINFO ;
     $c->{'bval'} ;
     $c->{'cachesize'} ;
     $c->{'psize'} ;
     $c->{'flags'} ;
     $c->{'lorder'} ;
     $c->{'reclen'} ;
     $c->{'bfname'} ;

The values stored in the hashes above are mostly the direct equivalent
of their C counterpart. Like their C counterparts, all are set to a
default set of values - that means you don't have to set I<all> of the
values when you only want to change one. Here is an example:

     $a = new DB_File::HASHINFO ;
     $a->{'cachesize'} =  12345 ;
     tie %y, 'DB_File', "filename", $flags, 0777, $a ;

A few of the values need extra discussion here. When used, the C
equivalent of the keys C<hash>, C<compare> and C<prefix> store pointers
to C functions. In B<DB_File> these keys are used to store references
to Perl subs. Below are templates for each of the subs:

    sub hash
    {
        my ($data) = @_ ;
        ...
        # return the hash value for $data
	return $hash ;
    }

    sub compare
    {
	my ($key, $key2) = @_ ;
        ...
        # return  0 if $key1 eq $key2
        #        -1 if $key1 lt $key2
        #         1 if $key1 gt $key2
        return (-1 , 0 or 1) ;
    }

    sub prefix
    {
	my ($key, $key2) = @_ ;
        ...
        # return number of bytes of $key2 which are 
        # necessary to determine that it is greater than $key1
        return $bytes ;
    }

See L<"Using BTREE"> for an example of using the C<compare>

=head2 Default Parameters

It is possible to omit some or all of the final 4 parameters in the
call to C<tie> and let them take default values. As DB_HASH is the most
common file format used, the call:

    tie %A, "DB_File", "filename" ;

is equivalent to:

    tie %A, "DB_File", "filename", O_CREAT|O_RDWR, 0640, $DB_HASH ;

It is also possible to omit the filename parameter as well, so the
call:

    tie %A, "DB_File" ;

is equivalent to:

    tie %A, "DB_File", undef, O_CREAT|O_RDWR, 0640, $DB_HASH ;

See L<"In Memory Databases"> for a discussion on the use of C<undef>
in place of a filename.

=head2 Handling duplicate keys in BTREE databases

The BTREE file type in Berkeley DB optionally allows a single key to be
associated with an arbitrary number of values. This option is enabled by
setting the flags element of C<$DB_BTREE> to R_DUP when creating the
database.

There are some difficulties in using the tied hash interface if you
want to manipulate a BTREE database with duplicate keys. Consider this
code:

    use DB_File ;
    use Fcntl ;
 
    $filename = "tree" ;
    unlink $filename ;
 
    # Enable duplicate records
    $DB_BTREE->{'flags'} = R_DUP ;
 
    tie %h, "DB_File", $filename, O_RDWR|O_CREAT, 0640, $DB_BTREE 
	or die "Cannot open $filename: $!\n";
 
    # Add some key/value pairs to the file
    $h{'Wall'} = 'Larry' ;
    $h{'Wall'} = 'Brick' ; # Note the duplicate key
    $h{'Smith'} = 'John' ;
    $h{'mouse'} = 'mickey' ;

    # iterate through the associative array
    # and print each key/value pair.
    foreach (keys %h)
      { print "$_  -> $h{$_}\n" }

Here is the output:

    Smith   -> John
    Wall    -> Larry
    Wall    -> Larry
    mouse   -> mickey

As you can see 2 records have been successfully created with key C<Wall>
- the only thing is, when they are retrieved from the database they
both I<seem> to have the same value, namely C<Larry>. The problem is
caused by the way that the associative array interface works.
Basically, when the associative array interface is used to fetch the
value associated with a given key, it will only ever retrieve the first
value.

Although it may not be immediately obvious from the code above, the
associative array interface can be used to write values with duplicate
keys, but it cannot be used to read them back from the database.

The way to get around this problem is to use the Berkeley DB API method
called C<seq>.  This method allows sequential access to key/value
pairs. See L<"Using the Berkeley DB API Directly"> for details of both
the C<seq> method and the API in general.

Here is the script above rewritten using the C<seq> API method.

    use DB_File ;
    use Fcntl ;
 
    $filename = "tree" ;
    unlink $filename ;
 
    # Enable duplicate records
    $DB_BTREE->{'flags'} = R_DUP ;
 
    $x = tie %h, "DB_File", $filename, O_RDWR|O_CREAT, 0640, $DB_BTREE 
	or die "Cannot open $filename: $!\n";
 
    # Add some key/value pairs to the file
    $h{'Wall'} = 'Larry' ;
    $h{'Wall'} = 'Brick' ; # Note the duplicate key
    $h{'Smith'} = 'John' ;
    $h{'mouse'} = 'mickey' ;
 
    # Point to the first record in the btree 
    $x->seq($key, $value, R_FIRST) ;

    # now iterate through the rest of the btree
    # and print each key/value pair.
    print "$key     -> $value\n" ;
    while ( $x->seq($key, $value, R_NEXT) == 0)
      {  print "$key -> $value\n" }
 
    undef $x ;
    untie %h ;

that prints:

    Smith   -> John
    Wall    -> Brick
    Wall    -> Larry
    mouse   -> mickey

This time we have got all the key/value pairs, including both the
values associated with the key C<Wall>.

C<DB_File> comes with a utility method, called C<get_dup>, to assist in
reading duplicate values from BTREE databases. The method can take the
following forms:

    $count = $x->get_dup($key) ;
    @list  = $x->get_dup($key) ;
    %list  = $x->get_dup($key, 1) ;

In a scalar context the method returns the number of values associated
with the key, C<$key>.

In list context, it returns all the values which match C<$key>. Note
that the values returned will be in an apparently random order.

If the second parameter is present and evaluates TRUE, the method
returns an associative array whose keys correspond to the the values
from the BTREE and whose values are all C<1>.

So assuming the database created above, we can use C<get_dups> like
this:

    $cnt  = $x->get_dups("Wall") ;
    print "Wall occurred $cnt times\n" ;

    %hash = $x->get_dups("Wall", 1) ;
    print "Larry is there\n" if $hash{'Larry'} ;

    @list = $x->get_dups("Wall") ;
    print "Wall =>	[@list]\n" ;

    @list = $x->get_dups("Smith") ;
    print "Smith =>	[@list]\n" ;
 
    @list = $x->get_dups("Dog") ;
    print "Dog =>	[@list]\n" ;


and it will print:

    Wall occurred 2 times
    Larry is there
    Wall =>	[Brick Larry]
    Smith =>	[John]
    Dog =>	[]

=head2 RECNO

In order to make RECNO more compatible with Perl the array offset for
all RECNO arrays begins at 0 rather than 1 as in Berkeley DB.

As with normal Perl arrays, a RECNO array can be accessed using
negative indexes. The index -1 refers to the last element of the array,
-2 the second last, and so on. Attempting to access an element before
the start of the array will raise a fatal run-time error.

=head2 In Memory Databases

Berkeley DB allows the creation of in-memory databases by using NULL
(that is, a C<(char *)0> in C) in place of the filename.  B<DB_File>
uses C<undef> instead of NULL to provide this functionality.


=head2 Using the Berkeley DB API Directly

As well as accessing Berkeley DB using a tied hash or array, it is also
possible to make direct use of most of the API functions defined in the
Berkeley DB documentation.

To do this you need to store a copy of the object returned from the tie.

	$db = tie %hash, "DB_File", "filename" ;

Once you have done that, you can access the Berkeley DB API functions
as B<DB_File> methods directly like this:

	$db->put($key, $value, R_NOOVERWRITE) ;

B<Important:> If you have saved a copy of the object returned from
C<tie>, the underlying database file will I<not> be closed until both
the tied variable is untied and all copies of the saved object are
destroyed.

    use DB_File ;
    $db = tie %hash, "DB_File", "filename" 
        or die "Cannot tie filename: $!" ;
    ...
    undef $db ;
    untie %hash ;

All the functions defined in L<dbopen> are available except for
close() and dbopen() itself. The B<DB_File> method interface to the
supported functions have been implemented to mirror the way Berkeley DB
works whenever possible. In particular note that:

=over 5

=item *

The methods return a status value. All return 0 on success.
All return -1 to signify an error and set C<$!> to the exact
error code. The return code 1 generally (but not always) means that the
key specified did not exist in the database.

Other return codes are defined. See below and in the Berkeley DB
documentation for details. The Berkeley DB documentation should be used
as the definitive source.

=item *

Whenever a Berkeley DB function returns data via one of its parameters,
the equivalent B<DB_File> method does exactly the same.

=item *

If you are careful, it is possible to mix API calls with the tied
hash/array interface in the same piece of code. Although only a few of
the methods used to implement the tied interface currently make use of
the cursor, you should always assume that the cursor has been changed
any time the tied hash/array interface is used. As an example, this
code will probably not do what you expect:

    $X = tie %x, 'DB_File', $filename, O_RDWR|O_CREAT, 0777, $DB_BTREE
        or die "Cannot tie $filename: $!" ;

    # Get the first key/value pair and set  the cursor
    $X->seq($key, $value, R_FIRST) ;

    # this line will modify the cursor
    $count = scalar keys %x ; 

    # Get the second key/value pair.
    # oops, it didn't, it got the last key/value pair!
    $X->seq($key, $value, R_NEXT) ;

The code above can be rearranged to get around the problem, like this:

    $X = tie %x, 'DB_File', $filename, O_RDWR|O_CREAT, 0777, $DB_BTREE
        or die "Cannot tie $filename: $!" ;

    # this line will modify the cursor
    $count = scalar keys %x ; 

    # Get the first key/value pair and set  the cursor
    $X->seq($key, $value, R_FIRST) ;

    # Get the second key/value pair.
    # worked this time.
    $X->seq($key, $value, R_NEXT) ;

=back

All the constants defined in L<dbopen> for use in the flags parameters
in the methods defined below are also available. Refer to the Berkeley
DB documentation for the precise meaning of the flags values.

Below is a list of the methods available.

=over 5

=item C<$status = $X-E<gt>get($key, $value [, $flags]) ;>

Given a key (C<$key>) this method reads the value associated with it
from the database. The value read from the database is returned in the
C<$value> parameter.

If the key does not exist the method returns 1.

No flags are currently defined for this method.

=item C<$status = $X-E<gt>put($key, $value [, $flags]) ;>

Stores the key/value pair in the database.

If you use either the R_IAFTER or R_IBEFORE flags, the C<$key> parameter
will have the record number of the inserted key/value pair set.

Valid flags are R_CURSOR, R_IAFTER, R_IBEFORE, R_NOOVERWRITE and
R_SETCURSOR.

=item C<$status = $X-E<gt>del($key [, $flags]) ;>

Removes all key/value pairs with key C<$key> from the database.

A return code of 1 means that the requested key was not in the
database.

R_CURSOR is the only valid flag at present.

=item C<$status = $X-E<gt>fd ;>

Returns the file descriptor for the underlying database.

See L<"Locking Databases"> for an example of how to make use of the
C<fd> method to lock your database.

=item C<$status = $X-E<gt>seq($key, $value, $flags) ;>

This interface allows sequential retrieval from the database. See
L<dbopen> for full details.

Both the C<$key> and C<$value> parameters will be set to the key/value
pair read from the database.

The flags parameter is mandatory. The valid flag values are R_CURSOR,
R_FIRST, R_LAST, R_NEXT and R_PREV.

=item C<$status = $X-E<gt>sync([$flags]) ;>

Flushes any cached buffers to disk.

R_RECNOSYNC is the only valid flag at present.

=back

=head1 EXAMPLES

It is always a lot easier to understand something when you see a real
example. So here are a few.

=head2 Using HASH

	use DB_File ;
	use Fcntl ;

	tie %h,  "DB_File", "hashed", O_RDWR|O_CREAT, 0640, $DB_HASH 
	    or die "Cannot open file 'hashed': $!\n";

	# Add a key/value pair to the file
	$h{"apple"} = "orange" ;

	# Check for existence of a key
	print "Exists\n" if $h{"banana"} ;

	# Delete 
	delete $h{"apple"} ;

	untie %h ;

=head2 Using BTREE

Here is a sample of code which uses BTREE. Just to make life more
interesting the default comparison function will not be used. Instead
a Perl sub, C<Compare()>, will be used to do a case insensitive
comparison.

        use DB_File ;
        use Fcntl ;

	sub Compare
        {
	    my ($key1, $key2) = @_ ;

	    "\L$key1" cmp "\L$key2" ;
	}

        $DB_BTREE->{'compare'} = 'Compare' ;

        tie %h, "DB_File", "tree", O_RDWR|O_CREAT, 0640, $DB_BTREE 
	    or die "Cannot open file 'tree': $!\n" ;

        # Add a key/value pair to the file
        $h{'Wall'} = 'Larry' ;
        $h{'Smith'} = 'John' ;
	$h{'mouse'} = 'mickey' ;
	$h{'duck'}   = 'donald' ;

        # Delete
        delete $h{"duck"} ;

	# Cycle through the keys printing them in order.
	# Note it is not necessary to sort the keys as
	# the btree will have kept them in order automatically.
	foreach (keys %h)
	  { print "$_\n" }

        untie %h ;

Here is the output from the code above.

	mouse
	Smith
	Wall


=head2 Using RECNO

Here is a simple example that uses RECNO.

	use DB_File ;
	use Fcntl ;

	$DB_RECNO->{'psize'} = 3000 ;

	tie @h, "DB_File", "text", O_RDWR|O_CREAT, 0640, $DB_RECNO 
	    or die "Cannot open file 'text': $!\n" ;

	# Add a key/value pair to the file
	$h[0] = "orange" ;

	# Check for existence of a key
	print "Exists\n" if $h[1] ;

	untie @h ;

=head2 Locking Databases

Concurrent access of a read-write database by several parties requires
them all to use some kind of locking.  Here's an example of Tom's that
uses the I<fd> method to get the file descriptor, and then a careful
open() to give something Perl will flock() for you.  Run this repeatedly
in the background to watch the locks granted in proper order.

    use Fcntl;
    use DB_File;

    use strict;

    sub LOCK_SH { 1 }
    sub LOCK_EX { 2 }
    sub LOCK_NB { 4 }
    sub LOCK_UN { 8 }

    my($oldval, $fd, $db, %db, $value, $key);

    $key = shift || 'default';
    $value = shift || 'magic';

    $value .= " $$";

    $db = tie(%db, 'DB_File', '/tmp/foo.db', O_CREAT|O_RDWR, 0644) 
	    || die "dbcreat /tmp/foo.db $!";
    $fd = $db->fd;
    print "$$: db fd is $fd\n";
    open(DB_FH, "+<&=$fd") || die "dup $!";


    unless (flock (DB_FH, LOCK_SH | LOCK_NB)) {
	print "$$: CONTENTION; can't read during write update!
		    Waiting for read lock ($!) ....";
	unless (flock (DB_FH, LOCK_SH)) { die "flock: $!" }
    } 
    print "$$: Read lock granted\n";

    $oldval = $db{$key};
    print "$$: Old value was $oldval\n";
    flock(DB_FH, LOCK_UN);

    unless (flock (DB_FH, LOCK_EX | LOCK_NB)) {
	print "$$: CONTENTION; must have exclusive lock!
		    Waiting for write lock ($!) ....";
	unless (flock (DB_FH, LOCK_EX)) { die "flock: $!" }
    } 

    print "$$: Write lock granted\n";
    $db{$key} = $value;
    $db->sync;
    sleep 10;

    flock(DB_FH, LOCK_UN);
    undef $db;
    untie %db;
    close(DB_FH);
    print "$$: Updated db to $key=$value\n";

=head1 HISTORY

=over

=item 0.1

First Release.

=item 0.2

When B<DB_File> is opening a database file it no longer terminates the
process if I<dbopen> returned an error. This allows file protection
errors to be caught at run time. Thanks to Judith Grass
E<lt>grass@cybercash.comE<gt> for spotting the bug.

=item 0.3

Added prototype support for multiple btree compare callbacks.

=item 1.0

B<DB_File> has been in use for over a year. To reflect that, the
version number has been incremented to 1.0.

Added complete support for multiple concurrent callbacks.

Using the I<push> method on an empty list didn't work properly. This
has been fixed.

=item 1.01

Fixed a core dump problem with SunOS.

The return value from TIEHASH wasn't set to NULL when dbopen returned
an error.

=item 1.02

Merged OS2 specific code into DB_File.xs

Removed some redundant code in DB_File.xs.

Documentation update.

Allow negative subscripts with RECNO interface.

Changed the default flags from O_RDWR to O_CREAT|O_RDWR.

The example code which showed how to lock a database needed a call to
C<sync> added. Without it the resultant database file was empty.

Added get_dups method.

=head1 WARNINGS

If you happen to find any other functions defined in the source for
this module that have not been mentioned in this document -- beware.  I
may drop them at a moments notice.

If you cannot find any, then either you didn't look very hard or the
moment has passed and I have dropped them.

=head1 BUGS

Some older versions of Berkeley DB had problems with fixed length
records using the RECNO file format. The newest version at the time of
writing was 1.85 - this seems to have fixed the problems with RECNO.

I am sure there are bugs in the code. If you do find any, or can
suggest any enhancements, I would welcome your comments.

=head1 AVAILABILITY

Berkeley DB is available at your nearest CPAN archive (see
L<perlmod/"CPAN"> for a list) in F<src/misc/db.1.85.tar.gz>, or via the
host F<ftp.cs.berkeley.edu> in F</ucb/4bsd/db.tar.gz>.  It is I<not> under
the GPL.

If you are running IRIX, then get Berkeley DB from
F<http://reality.sgi.com/ariel>. It has the patches necessary to
compile properly on IRIX 5.3.

=head1 SEE ALSO

L<perl(1)>, L<dbopen(3)>, L<hash(3)>, L<recno(3)>, L<btree(3)> 

Berkeley DB is available from F<ftp.cs.berkeley.edu> in the directory
F</ucb/4bsd>.

=head1 AUTHOR

The DB_File interface was written by Paul Marquess
E<lt>pmarquess@bfsec.bt.co.ukE<gt>.
Questions about the DB system itself may be addressed to Keith Bostic
E<lt>bostic@cs.berkeley.eduE<gt>.

=cut
