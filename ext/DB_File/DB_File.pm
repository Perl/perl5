# DB_File.pm -- Perl 5 interface to Berkeley DB 
#
# written by Paul Marquess (pmarquess@bfsec.bt.co.uk)
# last modified 18th Dec 1996
# version 1.09
#
#     Copyright (c) 1995, 1996 Paul Marquess. All rights reserved.
#     This program is free software; you can redistribute it and/or
#     modify it under the same terms as Perl itself.


package DB_File::HASHINFO ;

require 5.003 ;

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

    bless { VALID => { map {$_, 1} 
		       qw( bsize ffactor nelem cachesize hash lorder)
		     }, 
	    GOT   => {}
          }, $pkg ;
}


sub FETCH 
{  
    my $self  = shift ;
    my $key   = shift ;

    return $self->{GOT}{$key} if exists $self->{VALID}{$key}  ;

    my $pkg = ref $self ;
    croak "${pkg}::FETCH - Unknown element '$key'" ;
}


sub STORE 
{
    my $self  = shift ;
    my $key   = shift ;
    my $value = shift ;

    if ( exists $self->{VALID}{$key} )
    {
        $self->{GOT}{$key} = $value ;
        return ;
    }
    
    my $pkg = ref $self ;
    croak "${pkg}::STORE - Unknown element '$key'" ;
}

sub DELETE 
{
    my $self = shift ;
    my $key  = shift ;

    if ( exists $self->{VALID}{$key} )
    {
        delete $self->{GOT}{$key} ;
        return ;
    }
    
    my $pkg = ref $self ;
    croak "DB_File::HASHINFO::DELETE - Unknown element '$key'" ;
}

sub EXISTS
{
    my $self = shift ;
    my $key  = shift ;

    exists $self->{VALID}{$key} ;
}

sub NotHere
{
    my $self = shift ;
    my $method = shift ;

    croak ref($self) . " does not define the method ${method}" ;
}

sub DESTROY  { undef %{$_[0]} }
sub FIRSTKEY { my $self = shift ; $self->NotHere("FIRSTKEY") }
sub NEXTKEY  { my $self = shift ; $self->NotHere("NEXTKEY") }
sub CLEAR    { my $self = shift ; $self->NotHere("CLEAR") }

package DB_File::RECNOINFO ;

use strict ;

@DB_File::RECNOINFO::ISA = qw(DB_File::HASHINFO) ;

sub TIEHASH
{
    my $pkg = shift ;

    bless { VALID => { map {$_, 1} 
		       qw( bval cachesize psize flags lorder reclen bfname )
		     },
	    GOT   => {},
          }, $pkg ;
}

package DB_File::BTREEINFO ;

use strict ;

@DB_File::BTREEINFO::ISA = qw(DB_File::HASHINFO) ;

sub TIEHASH
{
    my $pkg = shift ;

    bless { VALID => { map {$_, 1} 
		       qw( flags cachesize maxkeypage minkeypage psize 
			   compare prefix lorder )
	    	     },
	    GOT   => {},
          }, $pkg ;
}


package DB_File ;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD $DB_BTREE $DB_HASH $DB_RECNO) ;
use Carp;


$VERSION = "1.09" ;

#typedef enum { DB_BTREE, DB_HASH, DB_RECNO } DBTYPE;
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


# import borrowed from IO::File
#   exports Fcntl constants if available.
sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export $pkg, $callpkg, @_;
    eval {
        require Fcntl;
        Exporter::export 'Fcntl', $callpkg, '/^O_/';
    };
}

bootstrap DB_File $VERSION;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

sub TIEHASH
{
    my (@arg) = @_ ;

    $arg[4] = tied %{ $arg[4] } 
	if @arg >= 5 && ref $arg[4] && $arg[4] =~ /=HASH/ && tied %{ $arg[4] } ;

    DoTie_(@arg) ;
}

*TIEARRAY = \&TIEHASH ;

sub get_dup
{
    croak "Usage: \$db->get_dup(key [,flag])\n"
        unless @_ == 2 or @_ == 3 ;
 
    my $db        = shift ;
    my $key       = shift ;
    my $flag	  = shift ;
    my $value 	  = 0 ;
    my $origkey   = $key ;
    my $wantarray = wantarray ;
    my %values	  = () ;
    my @values    = () ;
    my $counter   = 0 ;
    my $status    = 0 ;
 
    # iterate through the database until either EOF ($status == 0)
    # or a different key is encountered ($key ne $origkey).
    for ($status = $db->seq($key, $value, R_CURSOR()) ;
	 $status == 0 and $key eq $origkey ;
         $status = $db->seq($key, $value, R_NEXT()) ) {
 
        # save the value or count number of matches
        if ($wantarray) {
	    if ($flag)
                { ++ $values{$value} }
	    else
                { push (@values, $value) }
	}
        else
            { ++ $counter }
     
    }
 
    return ($wantarray ? ($flag ? %values : @values) : $counter) ;
}


1;
__END__

=cut

=head1 NAME

DB_File - Perl5 access to Berkeley DB

=head1 SYNOPSIS

 use DB_File ;
 
 [$X =] tie %hash,  'DB_File', [$filename, $flags, $mode, $DB_HASH] ;
 [$X =] tie %hash,  'DB_File', $filename, $flags, $mode, $DB_BTREE ;
 [$X =] tie @array, 'DB_File', $filename, $flags, $mode, $DB_RECNO ;

 $status = $X->del($key [, $flags]) ;
 $status = $X->put($key, $value [, $flags]) ;
 $status = $X->get($key, $value [, $flags]) ;
 $status = $X->seq($key, $value, $flags) ;
 $status = $X->sync([$flags]) ;
 $status = $X->fd ;

 # BTREE only
 $count = $X->get_dup($key) ;
 @list  = $X->get_dup($key) ;
 %list  = $X->get_dup($key, 1) ;

 # RECNO only
 $a = $X->length;
 $a = $X->pop ;
 $X->push(list);
 $a = $X->shift;
 $X->unshift(list);

 untie %hash ;
 untie @array ;

=head1 DESCRIPTION

B<DB_File> is a module which allows Perl programs to make use of the
facilities provided by Berkeley DB.  If you intend to use this
module you should really have a copy of the Berkeley DB manual pages at
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
See L<THE API INTERFACE>.

=head2 Opening a Berkeley DB Database File

Berkeley DB uses the function dbopen() to open or create a database.
Here is the C prototype for dbopen():

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
default values - that means you don't have to set I<all> of the
values when you only want to change one. Here is an example:

     $a = new DB_File::HASHINFO ;
     $a->{'cachesize'} =  12345 ;
     tie %y, 'DB_File', "filename", $flags, 0777, $a ;

A few of the options need extra discussion here. When used, the C
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

See L<Changing the BTREE sort order> for an example of using the
C<compare> template.

If you are using the DB_RECNO interface and you intend making use of
C<bval>, you should check out L<The bval option>.

=head2 Default Parameters

It is possible to omit some or all of the final 4 parameters in the
call to C<tie> and let them take default values. As DB_HASH is the most
common file format used, the call:

    tie %A, "DB_File", "filename" ;

is equivalent to:

    tie %A, "DB_File", "filename", O_CREAT|O_RDWR, 0666, $DB_HASH ;

It is also possible to omit the filename parameter as well, so the
call:

    tie %A, "DB_File" ;

is equivalent to:

    tie %A, "DB_File", undef, O_CREAT|O_RDWR, 0666, $DB_HASH ;

See L<In Memory Databases> for a discussion on the use of C<undef>
in place of a filename.

=head2 In Memory Databases

Berkeley DB allows the creation of in-memory databases by using NULL
(that is, a C<(char *)0> in C) in place of the filename.  B<DB_File>
uses C<undef> instead of NULL to provide this functionality.

=head1 DB_HASH

The DB_HASH file format is probably the most commonly used of the three
file formats that B<DB_File> supports. It is also very straightforward
to use.

=head2 A Simple Example.

This example shows how to create a database, add key/value pairs to the
database, delete keys/value pairs and finally how to enumerate the
contents of the database.

    use strict ;
    use DB_File ;
    use vars qw( %h $k $v ) ;

    tie %h, "DB_File", "fruit", O_RDWR|O_CREAT, 0640, $DB_HASH 
        or die "Cannot open file 'fruit': $!\n";

    # Add a few key/value pairs to the file
    $h{"apple"} = "red" ;
    $h{"orange"} = "orange" ;
    $h{"banana"} = "yellow" ;
    $h{"tomato"} = "red" ;

    # Check for existence of a key
    print "Banana Exists\n\n" if $h{"banana"} ;

    # Delete a key/value pair.
    delete $h{"apple"} ;

    # print the contents of the file
    while (($k, $v) = each %h)
      { print "$k -> $v\n" }

    untie %h ;

here is the output:

    Banana Exists
 
    orange -> orange
    tomato -> red
    banana -> yellow

Note that the like ordinary associative arrays, the order of the keys
retrieved is in an apparently random order.

=head1 DB_BTREE

The DB_BTREE format is useful when you want to store data in a given
order. By default the keys will be stored in lexical order, but as you
will see from the example shown in the next section, it is very easy to
define your own sorting function.

=head2 Changing the BTREE sort order

This script shows how to override the default sorting algorithm that
BTREE uses. Instead of using the normal lexical ordering, a case
insensitive compare function will be used.

    use strict ;
    use DB_File ;

    my %h ;

    sub Compare
    {
        my ($key1, $key2) = @_ ;
        "\L$key1" cmp "\L$key2" ;
    }

    # specify the Perl sub that will do the comparison
    $DB_BTREE->{'compare'} = \&Compare ;

    tie %h, "DB_File", "tree", O_RDWR|O_CREAT, 0640, $DB_BTREE 
        or die "Cannot open file 'tree': $!\n" ;

    # Add a key/value pair to the file
    $h{'Wall'} = 'Larry' ;
    $h{'Smith'} = 'John' ;
    $h{'mouse'} = 'mickey' ;
    $h{'duck'}  = 'donald' ;

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

There are a few point to bear in mind if you want to change the
ordering in a BTREE database:

=over 5

=item 1.

The new compare function must be specified when you create the database.

=item 2.

You cannot change the ordering once the database has been created. Thus
you must use the same compare function every time you access the
database.

=back 

=head2 Handling duplicate keys 

The BTREE file type optionally allows a single key to be associated
with an arbitrary number of values. This option is enabled by setting
the flags element of C<$DB_BTREE> to R_DUP when creating the database.

There are some difficulties in using the tied hash interface if you
want to manipulate a BTREE database with duplicate keys. Consider this
code:

    use strict ;
    use DB_File ;

    use vars qw($filename %h ) ;

    $filename = "tree" ;
    unlink $filename ;
 
    # Enable duplicate records
    $DB_BTREE->{'flags'} = R_DUP ;
 
    tie %h, "DB_File", $filename, O_RDWR|O_CREAT, 0640, $DB_BTREE 
	or die "Cannot open $filename: $!\n";
 
    # Add some key/value pairs to the file
    $h{'Wall'} = 'Larry' ;
    $h{'Wall'} = 'Brick' ; # Note the duplicate key
    $h{'Wall'} = 'Brick' ; # Note the duplicate key and value
    $h{'Smith'} = 'John' ;
    $h{'mouse'} = 'mickey' ;

    # iterate through the associative array
    # and print each key/value pair.
    foreach (keys %h)
      { print "$_  -> $h{$_}\n" }

    untie %h ;

Here is the output:

    Smith   -> John
    Wall    -> Larry
    Wall    -> Larry
    Wall    -> Larry
    mouse   -> mickey

As you can see 3 records have been successfully created with key C<Wall>
- the only thing is, when they are retrieved from the database they
I<seem> to have the same value, namely C<Larry>. The problem is caused
by the way that the associative array interface works. Basically, when
the associative array interface is used to fetch the value associated
with a given key, it will only ever retrieve the first value.

Although it may not be immediately obvious from the code above, the
associative array interface can be used to write values with duplicate
keys, but it cannot be used to read them back from the database.

The way to get around this problem is to use the Berkeley DB API method
called C<seq>.  This method allows sequential access to key/value
pairs. See L<THE API INTERFACE> for details of both the C<seq> method
and the API in general.

Here is the script above rewritten using the C<seq> API method.

    use strict ;
    use DB_File ;
 
    use vars qw($filename $x %h $status $key $value) ;

    $filename = "tree" ;
    unlink $filename ;
 
    # Enable duplicate records
    $DB_BTREE->{'flags'} = R_DUP ;
 
    $x = tie %h, "DB_File", $filename, O_RDWR|O_CREAT, 0640, $DB_BTREE 
	or die "Cannot open $filename: $!\n";
 
    # Add some key/value pairs to the file
    $h{'Wall'} = 'Larry' ;
    $h{'Wall'} = 'Brick' ; # Note the duplicate key
    $h{'Wall'} = 'Brick' ; # Note the duplicate key and value
    $h{'Smith'} = 'John' ;
    $h{'mouse'} = 'mickey' ;
 
    # iterate through the btree using seq
    # and print each key/value pair.
    $key = $value = 0 ;
    for ($status = $x->seq($key, $value, R_FIRST) ;
         $status == 0 ;
         $status = $x->seq($key, $value, R_NEXT) )
      {  print "$key -> $value\n" }
 
    undef $x ;
    untie %h ;

that prints:

    Smith   -> John
    Wall    -> Brick
    Wall    -> Brick
    Wall    -> Larry
    mouse   -> mickey

This time we have got all the key/value pairs, including the multiple
values associated with the key C<Wall>.

=head2 The get_dup method.

B<DB_File> comes with a utility method, called C<get_dup>, to assist in
reading duplicate values from BTREE databases. The method can take the
following forms:

    $count = $x->get_dup($key) ;
    @list  = $x->get_dup($key) ;
    %list  = $x->get_dup($key, 1) ;

In a scalar context the method returns the number of values associated
with the key, C<$key>.

In list context, it returns all the values which match C<$key>. Note
that the values will be returned in an apparently random order.

In list context, if the second parameter is present and evaluates TRUE,
the method returns an associative array. The keys of the associative
array correspond to the the values that matched in the BTREE and the
values of the array are a count of the number of times that particular
value occurred in the BTREE.

So assuming the database created above, we can use C<get_dup> like
this:

    my $cnt  = $x->get_dup("Wall") ;
    print "Wall occurred $cnt times\n" ;

    my %hash = $x->get_dup("Wall", 1) ;
    print "Larry is there\n" if $hash{'Larry'} ;
    print "There are $hash{'Brick'} Brick Walls\n" ;

    my @list = $x->get_dup("Wall") ;
    print "Wall =>	[@list]\n" ;

    @list = $x->get_dup("Smith") ;
    print "Smith =>	[@list]\n" ;
 
    @list = $x->get_dup("Dog") ;
    print "Dog =>	[@list]\n" ;


and it will print:

    Wall occurred 3 times
    Larry is there
    There are 2 Brick Walls
    Wall =>	[Brick Brick Larry]
    Smith =>	[John]
    Dog =>	[]

=head2 Matching Partial Keys 

The BTREE interface has a feature which allows partial keys to be
matched. This functionality is I<only> available when the C<seq> method
is used along with the R_CURSOR flag.

    $x->seq($key, $value, R_CURSOR) ;

Here is the relevant quote from the dbopen man page where it defines
the use of the R_CURSOR flag with seq:

    Note, for the DB_BTREE access method, the returned key is not
    necessarily an exact match for the specified key. The returned key
    is the smallest key greater than or equal to the specified key,
    permitting partial key matches and range searches.

In the example script below, the C<match> sub uses this feature to find
and print the first matching key/value pair given a partial key.

    use strict ;
    use DB_File ;
    use Fcntl ;

    use vars qw($filename $x %h $st $key $value) ;

    sub match
    {
        my $key = shift ;
        my $value = 0;
        my $orig_key = $key ;
        $x->seq($key, $value, R_CURSOR) ;
        print "$orig_key\t-> $key\t-> $value\n" ;
    }

    $filename = "tree" ;
    unlink $filename ;

    $x = tie %h, "DB_File", $filename, O_RDWR|O_CREAT, 0640, $DB_BTREE
        or die "Cannot open $filename: $!\n";
 
    # Add some key/value pairs to the file
    $h{'mouse'} = 'mickey' ;
    $h{'Wall'} = 'Larry' ;
    $h{'Walls'} = 'Brick' ; 
    $h{'Smith'} = 'John' ;
 

    $key = $value = 0 ;
    print "IN ORDER\n" ;
    for ($st = $x->seq($key, $value, R_FIRST) ;
	 $st == 0 ;
         $st = $x->seq($key, $value, R_NEXT) )
	
      {  print "$key -> $value\n" }
 
    print "\nPARTIAL MATCH\n" ;

    match "Wa" ;
    match "A" ;
    match "a" ;

    undef $x ;
    untie %h ;

Here is the output:

    IN ORDER
    Smith -> John
    Wall  -> Larry
    Walls -> Brick
    mouse -> mickey

    PARTIAL MATCH
    Wa -> Wall  -> Larry
    A  -> Smith -> John
    a  -> mouse -> mickey

=head1 DB_RECNO

DB_RECNO provides an interface to flat text files. Both variable and
fixed length records are supported.

In order to make RECNO more compatible with Perl the array offset for
all RECNO arrays begins at 0 rather than 1 as in Berkeley DB.

As with normal Perl arrays, a RECNO array can be accessed using
negative indexes. The index -1 refers to the last element of the array,
-2 the second last, and so on. Attempting to access an element before
the start of the array will raise a fatal run-time error.

=head2 The bval option

The operation of the bval option warrants some discussion. Here is the
definition of bval from the Berkeley DB 1.85 recno manual page:

    The delimiting byte to be used to mark  the  end  of  a
    record for variable-length records, and the pad charac-
    ter for fixed-length records.  If no  value  is  speci-
    fied,  newlines  (``\n'')  are  used to mark the end of
    variable-length records and  fixed-length  records  are
    padded with spaces.

The second sentence is wrong. In actual fact bval will only default to
C<"\n"> when the openinfo parameter in dbopen is NULL. If a non-NULL
openinfo parameter is used at all, the value that happens to be in bval
will be used. That means you always have to specify bval when making
use of any of the options in the openinfo parameter. This documentation
error will be fixed in the next release of Berkeley DB.

That clarifies the situation with regards Berkeley DB itself. What
about B<DB_File>? Well, the behavior defined in the quote above is
quite useful, so B<DB_File> conforms it.

That means that you can specify other options (e.g. cachesize) and
still have bval default to C<"\n"> for variable length records, and
space for fixed length records.

=head2 A Simple Example

Here is a simple example that uses RECNO.

    use strict ;
    use DB_File ;

    my @h ;
    tie @h, "DB_File", "text", O_RDWR|O_CREAT, 0640, $DB_RECNO 
        or die "Cannot open file 'text': $!\n" ;

    # Add a few key/value pairs to the file
    $h[0] = "orange" ;
    $h[1] = "blue" ;
    $h[2] = "yellow" ;

    # Check for existence of a key
    print "Element 1 Exists with value $h[1]\n" if $h[1] ;

    # use a negative index
    print "The last element is $h[-1]\n" ;
    print "The 2nd last element is $h[-2]\n" ;

    untie @h ;

Here is the output from the script:


    Element 1 Exists with value blue
    The last element is yellow
    The 2nd last element is blue

=head2 Extra Methods

As you can see from the example above, the tied array interface is
quite limited. To make the interface more useful, a number of methods
are supplied with B<DB_File> to simulate the standard array operations
that are not currently implemented in Perl's tied array interface. All
these methods are accessed via the object returned from the tie call.

Here are the methods:

=over 5

=item B<$X-E<gt>push(list) ;>

Pushes the elements of C<list> to the end of the array.

=item B<$value = $X-E<gt>pop ;>

Removes and returns the last element of the array.

=item B<$X-E<gt>shift>

Removes and returns the first element of the array.

=item B<$X-E<gt>unshift(list) ;>

Pushes the elements of C<list> to the start of the array.

=item B<$X-E<gt>length>

Returns the number of elements in the array.

=back

=head2 Another Example

Here is a more complete example that makes use of some of the methods
described above. It also makes use of the API interface directly (see 
L<THE API INTERFACE>).

    use strict ;
    use vars qw(@h $H $file $i) ;
    use DB_File ;
    use Fcntl ;
    
    $file = "text" ;

    unlink $file ;

    $H = tie @h, "DB_File", $file, O_RDWR|O_CREAT, 0640, $DB_RECNO 
        or die "Cannot open file $file: $!\n" ;
    
    # first create a text file to play with
    $h[0] = "zero" ;
    $h[1] = "one" ;
    $h[2] = "two" ;
    $h[3] = "three" ;
    $h[4] = "four" ;

    
    # Print the records in order.
    #
    # The length method is needed here because evaluating a tied
    # array in a scalar context does not return the number of
    # elements in the array.  

    print "\nORIGINAL\n" ;
    foreach $i (0 .. $H->length - 1) {
        print "$i: $h[$i]\n" ;
    }

    # use the push & pop methods
    $a = $H->pop ;
    $H->push("last") ;
    print "\nThe last record was [$a]\n" ;

    # and the shift & unshift methods
    $a = $H->shift ;
    $H->unshift("first") ;
    print "The first record was [$a]\n" ;

    # Use the API to add a new record after record 2.
    $i = 2 ;
    $H->put($i, "Newbie", R_IAFTER) ;

    # and a new record before record 1.
    $i = 1 ;
    $H->put($i, "New One", R_IBEFORE) ;

    # delete record 3
    $H->del(3) ;

    # now print the records in reverse order
    print "\nREVERSE\n" ;
    for ($i = $H->length - 1 ; $i >= 0 ; -- $i)
      { print "$i: $h[$i]\n" }

    # same again, but use the API functions instead
    print "\nREVERSE again\n" ;
    my ($s, $k, $v)  = (0, 0, 0) ;
    for ($s = $H->seq($k, $v, R_LAST) ; 
             $s == 0 ; 
             $s = $H->seq($k, $v, R_PREV))
      { print "$k: $v\n" }

    undef $H ;
    untie @h ;

and this is what it outputs:

    ORIGINAL
    0: zero
    1: one
    2: two
    3: three
    4: four

    The last record was [four]
    The first record was [zero]

    REVERSE
    5: last
    4: three
    3: Newbie
    2: one
    1: New One
    0: first

    REVERSE again
    5: last
    4: three
    3: Newbie
    2: one
    1: New One
    0: first

Notes:

=over 5

=item 1.

Rather than iterating through the array, C<@h> like this:

    foreach $i (@h)

it is necessary to use either this:

    foreach $i (0 .. $H->length - 1) 

or this:

    for ($a = $H->get($k, $v, R_FIRST) ;
         $a == 0 ;
         $a = $H->get($k, $v, R_NEXT) )

=item 2.

Notice that both times the C<put> method was used the record index was
specified using a variable, C<$i>, rather than the literal value
itself. This is because C<put> will return the record number of the
inserted line via that parameter.

=back

=head1 THE API INTERFACE

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

=item B<$status = $X-E<gt>get($key, $value [, $flags]) ;>

Given a key (C<$key>) this method reads the value associated with it
from the database. The value read from the database is returned in the
C<$value> parameter.

If the key does not exist the method returns 1.

No flags are currently defined for this method.

=item B<$status = $X-E<gt>put($key, $value [, $flags]) ;>

Stores the key/value pair in the database.

If you use either the R_IAFTER or R_IBEFORE flags, the C<$key> parameter
will have the record number of the inserted key/value pair set.

Valid flags are R_CURSOR, R_IAFTER, R_IBEFORE, R_NOOVERWRITE and
R_SETCURSOR.

=item B<$status = $X-E<gt>del($key [, $flags]) ;>

Removes all key/value pairs with key C<$key> from the database.

A return code of 1 means that the requested key was not in the
database.

R_CURSOR is the only valid flag at present.

=item B<$status = $X-E<gt>fd ;>

Returns the file descriptor for the underlying database.

See L<Locking Databases> for an example of how to make use of the
C<fd> method to lock your database.

=item B<$status = $X-E<gt>seq($key, $value, $flags) ;>

This interface allows sequential retrieval from the database. See
L<dbopen> for full details.

Both the C<$key> and C<$value> parameters will be set to the key/value
pair read from the database.

The flags parameter is mandatory. The valid flag values are R_CURSOR,
R_FIRST, R_LAST, R_NEXT and R_PREV.

=item B<$status = $X-E<gt>sync([$flags]) ;>

Flushes any cached buffers to disk.

R_RECNOSYNC is the only valid flag at present.

=back

=head1 HINTS AND TIPS 


=head2 Locking Databases

Concurrent access of a read-write database by several parties requires
them all to use some kind of locking.  Here's an example of Tom's that
uses the I<fd> method to get the file descriptor, and then a careful
open() to give something Perl will flock() for you.  Run this repeatedly
in the background to watch the locks granted in proper order.

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
    $db->sync;	# to flush
    sleep 10;

    flock(DB_FH, LOCK_UN);
    undef $db;
    untie %db;
    close(DB_FH);
    print "$$: Updated db to $key=$value\n";

=head2 Sharing databases with C applications

There is no technical reason why a Berkeley DB database cannot be
shared by both a Perl and a C application.

The vast majority of problems that are reported in this area boil down
to the fact that C strings are NULL terminated, whilst Perl strings are
not. 

Here is a real example. Netscape 2.0 keeps a record of the locations you
visit along with the time you last visited them in a DB_HASH database.
This is usually stored in the file F<~/.netscape/history.db>. The key
field in the database is the location string and the value field is the
time the location was last visited stored as a 4 byte binary value.

If you haven't already guessed, the location string is stored with a
terminating NULL. This means you need to be careful when accessing the
database.

Here is a snippet of code that is loosely based on Tom Christiansen's
I<ggh> script (available from your nearest CPAN archive in
F<authors/id/TOMC/scripts/nshist.gz>).

    use strict ;
    use DB_File ;
    use Fcntl ;

    use vars qw( $dotdir $HISTORY %hist_db $href $binary_time $date ) ;
    $dotdir = $ENV{HOME} || $ENV{LOGNAME};

    $HISTORY = "$dotdir/.netscape/history.db";

    tie %hist_db, 'DB_File', $HISTORY
        or die "Cannot open $HISTORY: $!\n" ;;

    # Dump the complete database
    while ( ($href, $binary_time) = each %hist_db ) {

        # remove the terminating NULL
        $href =~ s/\x00$// ;

        # convert the binary time into a user friendly string
        $date = localtime unpack("V", $binary_time);
        print "$date $href\n" ;
    }

    # check for the existence of a specific key
    # remember to add the NULL
    if ( $binary_time = $hist_db{"http://mox.perl.com/\x00"} ) {
        $date = localtime unpack("V", $binary_time) ;
        print "Last visited mox.perl.com on $date\n" ;
    }
    else {
        print "Never visited mox.perl.com\n"
    }

    untie %hist_db ;


=head1 COMMON QUESTIONS

=head2 Why is there Perl source in my database?

If you look at the contents of a database file created by DB_File,
there can sometimes be part of a Perl script included in it.

This happens because Berkeley DB uses dynamic memory to allocate
buffers which will subsequently be written to the database file. Being
dynamic, the memory could have been used for anything before DB
malloced it. As Berkeley DB doesn't clear the memory once it has been
allocated, the unused portions will contain random junk. In the case
where a Perl script gets written to the database, the random junk will
correspond to an area of dynamic memory that happened to be used during
the compilation of the script.

Unless you don't like the possibility of there being part of your Perl
scripts embedded in a database file, this is nothing to worry about.

=head2 How do I store complex data structures with DB_File?

Although B<DB_File> cannot do this directly, there is a module which
can layer transparently over B<DB_File> to accomplish this feat.

Check out the MLDBM module, available on CPAN in the directory
F<modules/by-module/MLDBM>.

=head2 What does "Invalid Argument" mean?

You will get this error message when one of the parameters in the
C<tie> call is wrong. Unfortunately there are quite a few parameters to
get wrong, so it can be difficult to figure out which one it is.

Here are a couple of possibilities:

=over 5

=item 1.

Attempting to reopen a database without closing it. 

=item 2.

Using the O_WRONLY flag.

=back

=head2 What does "Bareword 'DB_File' not allowed" mean? 

You will encounter this particular error message when you have the
C<strict 'subs'> pragma (or the full strict pragma) in your script.
Consider this script:

    use strict ;
    use DB_File ;
    use vars qw(%x) ;
    tie %x, DB_File, "filename" ;

Running it produces the error in question:

    Bareword "DB_File" not allowed while "strict subs" in use 

To get around the error, place the word C<DB_File> in either single or
double quotes, like this:

    tie %x, "DB_File", "filename" ;

Although it might seem like a real pain, it is really worth the effort
of having a C<use strict> in all your scripts.

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

Merged OS/2 specific code into DB_File.xs

Removed some redundant code in DB_File.xs.

Documentation update.

Allow negative subscripts with RECNO interface.

Changed the default flags from O_RDWR to O_CREAT|O_RDWR.

The example code which showed how to lock a database needed a call to
C<sync> added. Without it the resultant database file was empty.

Added get_dup method.

=item 1.03

Documentation update.

B<DB_File> now imports the constants (O_RDWR, O_CREAT etc.) from Fcntl
automatically.

The standard hash function C<exists> is now supported.

Modified the behavior of get_dup. When it returns an associative
array, the value is the count of the number of matching BTREE values.

=item 1.04

Minor documentation changes.

Fixed a bug in hash_cb. Patches supplied by Dave Hammen,
E<lt>hammen@gothamcity.jsc.nasa.govE<gt>.

Fixed a bug with the constructors for DB_File::HASHINFO,
DB_File::BTREEINFO and DB_File::RECNOINFO. Also tidied up the
constructors to make them C<-w> clean.

Reworked part of the test harness to be more locale friendly.

=item 1.05

Made all scripts in the documentation C<strict> and C<-w> clean.

Added logic to F<DB_File.xs> to allow the module to be built after Perl
is installed.

=item 1.06

Minor namespace cleanup: Localized C<PrintBtree>.

=item 1.07

Fixed bug with RECNO, where bval wasn't defaulting to "\n".

=item 1.08

Documented operation of bval.

=item 1.09

Minor bug fix in DB_File::HASHINFO, DB_File::RECNOINFO and
DB_File::BTREEINFO.

Changed default mode to 0666.

=back

=head1 BUGS

Some older versions of Berkeley DB had problems with fixed length
records using the RECNO file format. The newest version at the time of
writing was 1.85 - this seems to have fixed the problems with RECNO.

I am sure there are bugs in the code. If you do find any, or can
suggest any enhancements, I would welcome your comments.

=head1 AVAILABILITY

B<DB_File> comes with the standard Perl source distribution. Look in
the directory F<ext/DB_File>.

Berkeley DB is available at your nearest CPAN archive (see
L<perlmod/"CPAN"> for a list) in F<src/misc/db.1.85.tar.gz>, or via the
host F<ftp.cs.berkeley.edu> in F</ucb/4bsd/db.tar.gz>.  Alternatively,
check out the Berkeley DB home page at F<http://www.bostic.com/db>. It
is I<not> under the GPL.

If you are running IRIX, then get Berkeley DB from
F<http://reality.sgi.com/ariel>. It has the patches necessary to
compile properly on IRIX 5.3.

=head1 SEE ALSO

L<perl(1)>, L<dbopen(3)>, L<hash(3)>, L<recno(3)>, L<btree(3)> 

=head1 AUTHOR

The DB_File interface was written by Paul Marquess
E<lt>pmarquess@bfsec.bt.co.ukE<gt>.
Questions about the DB system itself may be addressed to Keith Bostic
E<lt>bostic@cs.berkeley.eduE<gt>.

=cut
