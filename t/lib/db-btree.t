#!./perl -w

BEGIN {
    @INC = '../lib' if -d '../lib' ;
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bDB_File\b/) {
	print "1..0\n";
	exit 0;
    }
}

use DB_File; 
use Fcntl;

print "1..91\n";

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}

sub lexical
{
    my(@a) = unpack ("C*", $a) ;
    my(@b) = unpack ("C*", $b) ;

    my $len = (@a > @b ? @b : @a) ;
    my $i = 0 ;

    foreach $i ( 0 .. $len -1) {
        return $a[$i] - $b[$i] if $a[$i] != $b[$i] ;
    }

    return @a - @b ;
}

$Dfile = "dbbtree.tmp";
unlink $Dfile;

umask(0);

# Check the interface to BTREEINFO

my $dbh = new DB_File::BTREEINFO ;
ok(1, $dbh->{flags} == 0) ;
ok(2, $dbh->{cachesize} == 0) ;
ok(3, $dbh->{psize} == 0) ;
ok(4, $dbh->{lorder} == 0) ;
ok(5, $dbh->{minkeypage} == 0) ;
ok(6, $dbh->{maxkeypage} == 0) ;
$^W = 0 ;
ok(7, $dbh->{compare} == undef) ;
ok(8, $dbh->{prefix} == undef) ;
$^W = 1 ;

$dbh->{flags} = 3000 ;
ok(9, $dbh->{flags} == 3000) ;

$dbh->{cachesize} = 9000 ;
ok(10, $dbh->{cachesize} == 9000);

$dbh->{psize} = 400 ;
ok(11, $dbh->{psize} == 400) ;

$dbh->{lorder} = 65 ;
ok(12, $dbh->{lorder} == 65) ;

$dbh->{minkeypage} = 123 ;
ok(13, $dbh->{minkeypage} == 123) ;

$dbh->{maxkeypage} = 1234 ;
ok(14, $dbh->{maxkeypage} == 1234 );

$dbh->{compare} = 1234 ;
ok(15, $dbh->{compare} == 1234) ;

$dbh->{prefix} = 1234 ;
ok(16, $dbh->{prefix} == 1234 );

# Check that an invalid entry is caught both for store & fetch
eval '$dbh->{fred} = 1234' ;
ok(17, $@ =~ /^DB_File::BTREEINFO::STORE - Unknown element 'fred' at/ ) ;
eval '$q = $dbh->{fred}' ;
ok(18, $@ =~ /^DB_File::BTREEINFO::FETCH - Unknown element 'fred' at/ ) ;

# Now check the interface to BTREE

ok(19, $X = tie(%h, 'DB_File',$Dfile, O_RDWR|O_CREAT, 0640, $DB_BTREE )) ;

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
   $blksize,$blocks) = stat($Dfile);
ok(20, ($mode & 0777) == ($^O eq 'os2' ? 0666 : 0640) );

while (($key,$value) = each(%h)) {
    $i++;
}
ok(21, !$i ) ;

$h{'goner1'} = 'snork';

$h{'abc'} = 'ABC';
ok(22, $h{'abc'} eq 'ABC' );
ok(23, ! defined $h{'jimmy'} ) ;
ok(24, ! exists $h{'jimmy'} ) ;
ok(25,  defined $h{'abc'} ) ;

$h{'def'} = 'DEF';
$h{'jkl','mno'} = "JKL\034MNO";
$h{'a',2,3,4,5} = join("\034",'A',2,3,4,5);
$h{'a'} = 'A';

#$h{'b'} = 'B';
$X->STORE('b', 'B') ;

$h{'c'} = 'C';

#$h{'d'} = 'D';
$X->put('d', 'D') ;

$h{'e'} = 'E';
$h{'f'} = 'F';
$h{'g'} = 'X';
$h{'h'} = 'H';
$h{'i'} = 'I';

$h{'goner2'} = 'snork';
delete $h{'goner2'};


# IMPORTANT - $X must be undefined before the untie otherwise the
#             underlying DB close routine will not get called.
undef $X ;
untie(%h);


# tie to the same file again
ok(26, $X = tie(%h,'DB_File',$Dfile, O_RDWR, 0640, $DB_BTREE)) ;

# Modify an entry from the previous tie
$h{'g'} = 'G';

$h{'j'} = 'J';
$h{'k'} = 'K';
$h{'l'} = 'L';
$h{'m'} = 'M';
$h{'n'} = 'N';
$h{'o'} = 'O';
$h{'p'} = 'P';
$h{'q'} = 'Q';
$h{'r'} = 'R';
$h{'s'} = 'S';
$h{'t'} = 'T';
$h{'u'} = 'U';
$h{'v'} = 'V';
$h{'w'} = 'W';
$h{'x'} = 'X';
$h{'y'} = 'Y';
$h{'z'} = 'Z';

$h{'goner3'} = 'snork';

delete $h{'goner1'};
$X->DELETE('goner3');

@keys = keys(%h);
@values = values(%h);

ok(27, $#keys == 29 && $#values == 29) ;

$i = 0 ;
while (($key,$value) = each(%h)) {
    if ($key eq $keys[$i] && $value eq $values[$i] && $key eq lc($value)) {
	$key =~ y/a-z/A-Z/;
	$i++ if $key eq $value;
    }
}

ok(28, $i == 30) ;

@keys = ('blurfl', keys(%h), 'dyick');
ok(29, $#keys == 31) ;

#Check that the keys can be retrieved in order
my @b = keys %h ;
my @c = sort lexical @b ;
ok(30, ArrayCompare(\@b, \@c)) ;

$h{'foo'} = '';
ok(31, $h{'foo'} eq '' ) ;

$h{''} = 'bar';
ok(32, $h{''} eq 'bar' );

# check cache overflow and numeric keys and contents
$ok = 1;
for ($i = 1; $i < 200; $i++) { $h{$i + 0} = $i + 0; }
for ($i = 1; $i < 200; $i++) { $ok = 0 unless $h{$i} == $i; }
ok(33, $ok);

($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
   $blksize,$blocks) = stat($Dfile);
ok(34, $size > 0 );

@h{0..200} = 200..400;
@foo = @h{0..200};
ok(35, join(':',200..400) eq join(':',@foo) );

# Now check all the non-tie specific stuff


# Check R_NOOVERWRITE flag will make put fail when attempting to overwrite
# an existing record.
 
$status = $X->put( 'x', 'newvalue', R_NOOVERWRITE) ;
ok(36, $status == 1 );
 
# check that the value of the key 'x' has not been changed by the 
# previous test
ok(37, $h{'x'} eq 'X' );

# standard put
$status = $X->put('key', 'value') ;
ok(38, $status == 0 );

#check that previous put can be retrieved
$value = 0 ;
$status = $X->get('key', $value) ;
ok(39, $status == 0 );
ok(40, $value eq 'value' );

# Attempting to delete an existing key should work

$status = $X->del('q') ;
ok(41, $status == 0 );
$status = $X->del('') ;
ok(42, $status == 0 );

# Make sure that the key deleted, cannot be retrieved
$^W = 0 ;
ok(43, $h{'q'} eq undef) ;
ok(44, $h{''} eq undef) ;
$^W = 1 ;

undef $X ;
untie %h ;

ok(45, $X = tie(%h, 'DB_File',$Dfile, O_RDWR, 0640, $DB_BTREE ));

# Attempting to delete a non-existant key should fail

$status = $X->del('joe') ;
ok(46, $status == 1 );

# Check the get interface

# First a non-existing key
$status = $X->get('aaaa', $value) ;
ok(47, $status == 1 );

# Next an existing key
$status = $X->get('a', $value) ;
ok(48, $status == 0 );
ok(49, $value eq 'A' );

# seq
# ###

# use seq to find an approximate match
$key = 'ke' ;
$value = '' ;
$status = $X->seq($key, $value, R_CURSOR) ;
ok(50, $status == 0 );
ok(51, $key eq 'key' );
ok(52, $value eq 'value' );

# seq when the key does not match
$key = 'zzz' ;
$value = '' ;
$status = $X->seq($key, $value, R_CURSOR) ;
ok(53, $status == 1 );


# use seq to set the cursor, then delete the record @ the cursor.

$key = 'x' ;
$value = '' ;
$status = $X->seq($key, $value, R_CURSOR) ;
ok(54, $status == 0 );
ok(55, $key eq 'x' );
ok(56, $value eq 'X' );
$status = $X->del(0, R_CURSOR) ;
ok(57, $status == 0 );
$status = $X->get('x', $value) ;
ok(58, $status == 1 );

# ditto, but use put to replace the key/value pair.
$key = 'y' ;
$value = '' ;
$status = $X->seq($key, $value, R_CURSOR) ;
ok(59, $status == 0 );
ok(60, $key eq 'y' );
ok(61, $value eq 'Y' );

$key = "replace key" ;
$value = "replace value" ;
$status = $X->put($key, $value, R_CURSOR) ;
ok(62, $status == 0 );
ok(63, $key eq 'replace key' );
ok(64, $value eq 'replace value' );
$status = $X->get('y', $value) ;
ok(65, $status == 1 );

# use seq to walk forwards through a file 

$status = $X->seq($key, $value, R_FIRST) ;
ok(66, $status == 0 );
$previous = $key ;

$ok = 1 ;
while (($status = $X->seq($key, $value, R_NEXT)) == 0)
{
    ($ok = 0), last if ($previous cmp $key) == 1 ;
}

ok(67, $status == 1 );
ok(68, $ok == 1 );

# use seq to walk backwards through a file 
$status = $X->seq($key, $value, R_LAST) ;
ok(69, $status == 0 );
$previous = $key ;

$ok = 1 ;
while (($status = $X->seq($key, $value, R_PREV)) == 0)
{
    ($ok = 0), last if ($previous cmp $key) == -1 ;
    #print "key = [$key] value = [$value]\n" ;
}

ok(70, $status == 1 );
ok(71, $ok == 1 );


# check seq FIRST/LAST

# sync
# ####

$status = $X->sync ;
ok(72, $status == 0 );


# fd
# ##

$status = $X->fd ;
ok(73, $status != 0 );


undef $X ;
untie %h ;

unlink $Dfile;

# Now try an in memory file
ok(74, $Y = tie(%h, 'DB_File',undef, O_RDWR|O_CREAT, 0640, $DB_BTREE ));

# fd with an in memory file should return failure
$status = $Y->fd ;
ok(75, $status == -1 );


undef $Y ;
untie %h ;

# Duplicate keys
my $bt = new DB_File::BTREEINFO ;
$bt->{flags} = R_DUP ;
ok(76, $YY = tie(%hh, 'DB_File', $Dfile, O_RDWR|O_CREAT, 0640, $bt )) ;

$hh{'Wall'} = 'Larry' ;
$hh{'Wall'} = 'Stone' ; # Note the duplicate key
$hh{'Wall'} = 'Brick' ; # Note the duplicate key
$hh{'Wall'} = 'Brick' ; # Note the duplicate key and value
$hh{'Smith'} = 'John' ;
$hh{'mouse'} = 'mickey' ;

# first work in scalar context
ok(77, scalar $YY->get_dup('Unknown') == 0 );
ok(78, scalar $YY->get_dup('Smith') == 1 );
ok(79, scalar $YY->get_dup('Wall') == 4 );

# now in list context
my @unknown = $YY->get_dup('Unknown') ;
ok(80, "@unknown" eq "" );

my @smith = $YY->get_dup('Smith') ;
ok(81, "@smith" eq "John" );

{
my @wall = $YY->get_dup('Wall') ;
my %wall ;
@wall{@wall} = @wall ;
ok(82, (@wall == 4 && $wall{'Larry'} && $wall{'Stone'} && $wall{'Brick'}) );
}

# hash
my %unknown = $YY->get_dup('Unknown', 1) ;
ok(83, keys %unknown == 0 );

my %smith = $YY->get_dup('Smith', 1) ;
ok(84, keys %smith == 1 && $smith{'John'}) ;

my %wall = $YY->get_dup('Wall', 1) ;
ok(85, keys %wall == 3 && $wall{'Larry'} == 1 && $wall{'Stone'} == 1 
		&& $wall{'Brick'} == 2);

undef $YY ;
untie %hh ;
unlink $Dfile;


# test multiple callbacks
$Dfile1 = "btree1" ;
$Dfile2 = "btree2" ;
$Dfile3 = "btree3" ;
 
$dbh1 = new DB_File::BTREEINFO ;
$dbh1->{compare} = sub { $_[0] <=> $_[1] } ;
 
$dbh2 = new DB_File::BTREEINFO ;
$dbh2->{compare} = sub { $_[0] cmp $_[1] } ;
 
$dbh3 = new DB_File::BTREEINFO ;
$dbh3->{compare} = sub { length $_[0] <=> length $_[1] } ;
 
 
tie(%h, 'DB_File',$Dfile1, O_RDWR|O_CREAT, 0640, $dbh1 ) ;
tie(%g, 'DB_File',$Dfile2, O_RDWR|O_CREAT, 0640, $dbh2 ) ;
tie(%k, 'DB_File',$Dfile3, O_RDWR|O_CREAT, 0640, $dbh3 ) ;
 
@Keys = qw( 0123 12 -1234 9 987654321 def  ) ;
$^W = 0 ;
@srt_1 = sort { $a <=> $b } @Keys ;
$^W = 1 ;
@srt_2 = sort { $a cmp $b } @Keys ;
@srt_3 = sort { length $a <=> length $b } @Keys ;
 
foreach (@Keys) {
    $^W = 0 ; 
    $h{$_} = 1 ; 
    $^W = 1 ;
    $g{$_} = 1 ;
    $k{$_} = 1 ;
}
 
sub ArrayCompare
{
    my($a, $b) = @_ ;
 
    return 0 if @$a != @$b ;
 
    foreach (1 .. length @$a)
    {
        return 0 unless $$a[$_] eq $$b[$_] ;
    }
 
    1 ;
}
 
ok(86, ArrayCompare (\@srt_1, [keys %h]) );
ok(87, ArrayCompare (\@srt_2, [keys %g]) );
ok(88, ArrayCompare (\@srt_3, [keys %k]) );

untie %h ;
untie %g ;
untie %k ;
unlink $Dfile1, $Dfile2, $Dfile3 ;

# clear
# #####

ok(89, tie(%h, 'DB_File', $Dfile1, O_RDWR|O_CREAT, 0640, $DB_BTREE ) );
foreach (1 .. 10)
  { $h{$_} = $_ * 100 }

# check that there are 10 elements in the hash
$i = 0 ;
while (($key,$value) = each(%h)) {
    $i++;
}
ok(90, $i == 10);

# now clear the hash
%h = () ;

# check it is empty
$i = 0 ;
while (($key,$value) = each(%h)) {
    $i++;
}
ok(91, $i == 0);

untie %h ;
unlink $Dfile1 ;

exit ;
