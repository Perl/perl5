#!./perl

# Add new tests to the end with format:
# ########
#
# # test description
# Test code
# EXPECT
# Warn or die msgs (if any) at - line 1234
#

chdir 't' if -d 't';
require './test.pl';
set_up_inc('../lib');

$|=1;

run_multiple_progs('', \*DATA);

done_testing();

__END__

# NAME standard behaviour, without any extra references
use Tie::Hash ;
no strict 'subs';
no warnings;
tie my %h, Tie::StdHash;
untie %h;
EXPECT
########
# SKIP ?!defined &DynaLoader::boot_DynaLoader && !eval 'require base'
# (skip under miniperl if base.pm is not in lib/ yet)

# NAME standard behaviour, without any extra references
no strict 'subs';
use Tie::Hash ;
{package Tie::HashUntie;
 use base 'Tie::StdHash';
 sub UNTIE
  {
   warn "Untied\n";
  }
}
tie my %h, Tie::HashUntie;
untie %h;
EXPECT
Untied
########

# NAME standard behaviour, with 1 extra reference
no strict 'subs';
no warnings;
use Tie::Hash ;
$a = tie my %h, Tie::StdHash;
untie %h;
EXPECT
########

# NAME standard behaviour, with 1 extra reference via tied
no strict 'subs';
no warnings;
use Tie::Hash ;
tie my %h, Tie::StdHash;
$a = tied %h;
untie %h;
EXPECT
########

# NAME standard behaviour, with 1 extra reference which is destroyed
no strict 'subs';
use Tie::Hash ;
$a = tie my %h, Tie::StdHash;
$a = 0 ;
untie %h;
EXPECT
########

# NAME standard behaviour, with 1 extra reference via tied which is destroyed
no strict 'subs';
use Tie::Hash ;
tie my %h, Tie::StdHash;
$a = tied %h;
$a = 0 ;
untie %h;
EXPECT
########

# NAME strict behaviour, without any extra references
no strict 'subs';
use warnings 'untie';
use Tie::Hash ;
tie my %h, Tie::StdHash;
untie %h;
EXPECT
########

# NAME strict behaviour, with 1 extra references generating an error
no strict 'subs';
use warnings 'untie';
use Tie::Hash ;
$a = tie my %h, Tie::StdHash;
untie %h;
EXPECT
untie attempted while 1 inner references still exist at - line 6.
########

# NAME strict behaviour, with 1 extra references via tied generating an error
no strict 'subs';
use warnings 'untie';
use Tie::Hash ;
tie my %h, Tie::StdHash;
$a = tied %h;
untie %h;
EXPECT
untie attempted while 1 inner references still exist at - line 7.
########

# NAME strict behaviour, with 1 extra references which are destroyed
no strict 'subs';
use warnings 'untie';
use Tie::Hash ;
$a = tie my %h, Tie::StdHash;
$a = 0 ;
untie %h;
EXPECT
########

# NAME strict behaviour, with extra 1 references via tied which are destroyed
no strict 'subs';
use warnings 'untie';
use Tie::Hash ;
tie my %h, Tie::StdHash;
$a = tied %h;
$a = 0 ;
untie %h;
EXPECT
########

# NAME strict error behaviour, with 2 extra references
no strict 'subs';
use warnings 'untie';
use Tie::Hash ;
my %h;
my $a = tie %h, Tie::StdHash;
my $b = tied %h ;
untie %h;
EXPECT
untie attempted while 2 inner references still exist at - line 8.
########

# NAME strict behaviour, check scope of strictness.
no strict 'subs';
no warnings 'untie';
use Tie::Hash ;
my ($A, $B, $C, %H, );
$A = tie %H, Tie::StdHash;
$C = $B = tied %H ;
{
    use warnings 'untie';
    use Tie::Hash ;
    tie my %h, Tie::StdHash;
    untie %h;
}
untie %H;
EXPECT
########

# NAME Forbidden aggregate self-ties
sub Self::TIEHASH { bless $_[1], $_[0] }
{
    my %c;
    tie %c, 'Self', \%c;
}
EXPECT
Self-ties of arrays and hashes are not supported at - line 5.
########

# NAME Allowed scalar self-ties
my $destroyed = 0;
sub Self::TIESCALAR { bless $_[1], $_[0] }
sub Self::DESTROY   { $destroyed = 1; }
{
    my $c = 42;
    tie $c, 'Self', \$c;
}
die "self-tied scalar not DESTROYed" unless $destroyed == 1;
EXPECT
########

# NAME Allowed glob self-ties
my $destroyed = 0;
my $printed   = 0;
sub Self2::TIEHANDLE { bless $_[1], $_[0] }
sub Self2::DESTROY   { $destroyed = 1; }
sub Self2::PRINT     { $printed = 1; }
{
    use Symbol;
    my $c = gensym;
    tie *$c, 'Self2', $c;
    print $c 'Hello';
}
die "self-tied glob not PRINTed" unless $printed == 1;
die "self-tied glob not DESTROYed" unless $destroyed == 1;
EXPECT
########

# NAME Allowed IO self-ties
my $destroyed = 0;
my $printed;
sub Self3::TIEHANDLE { bless $_[1], $_[0] }
sub Self3::DESTROY   { $destroyed = 1; }
sub Self3::PRINT     { $printed = 1; }
{
    use Symbol 'geniosym';
    my $c = geniosym;
    tie *$c, 'Self3', $c;
    print $c 'Hello';
}
die "self-tied IO not PRINTed" unless $printed == 1;
die "self-tied IO not DESTROYed" unless $destroyed == 1;
EXPECT
########

# TODO IO "self-tie" via TEMP glob
# NAME IO "self-tie" via TEMP glob
my $printed;
my $destroyed = 0;
sub Self3::TIEHANDLE { bless $_[1], $_[0] }
sub Self3::DESTROY   { $destroyed = 1; }
sub Self3::PRINT     { $printed = 1; }
{
    use Symbol 'geniosym';
    my $c = geniosym;
    tie *$c, 'Self3', \*$c;
    print $c 'Hello';
}
die "IO tied to TEMP glob not PRINTed" unless $printed == 1;
die "IO tied to TEMP glob not DESTROYed" unless $destroyed == 1;
EXPECT
########

# NAME Interaction of tie and vec

no strict;
my ($a, $b);
use Tie::Scalar;
tie $a,Tie::StdScalar or die;
vec($b,1,1)=1;
$a = $b;
vec($a,1,1)=0;
vec($b,1,1)=0;
die unless $a eq $b;
EXPECT
########

# NAME correct unlocalisation of tied hashes (patch #16431)
no strict 'subs';
use Tie::Hash ;
our %hash;
tie our %tied, Tie::StdHash;;
{ local $hash{'foo'} } warn "plain hash bad unlocalize" if exists $hash{'foo'};
{ local $tied{'foo'} } warn "tied hash bad unlocalize" if exists $tied{'foo'};
{ local $ENV{'foo'}  } warn "%ENV bad unlocalize" if exists $ENV{'foo'};
EXPECT
########

# NAME An attempt at lvalueable barewords broke this
no strict 'subs';
tie FH, 'main';
EXPECT
Can't modify constant item in tie at - line 3, near "'main';"
Execution of - aborted due to compilation errors.
########

# NAME localizing tied hash slices
$ENV{FooA} = 1;
$ENV{FooB} = 2;
print exists $ENV{FooA} ? 1 : 0, "\n";
print exists $ENV{FooB} ? 2 : 0, "\n";
print exists $ENV{FooC} ? 3 : 0, "\n";
{
    local @ENV{qw(FooA FooC)};
    print exists $ENV{FooA} ? 4 : 0, "\n";
    print exists $ENV{FooB} ? 5 : 0, "\n";
    print exists $ENV{FooC} ? 6 : 0, "\n";
}
print exists $ENV{FooA} ? 7 : 0, "\n";
print exists $ENV{FooB} ? 8 : 0, "\n";
print exists $ENV{FooC} ? 9 : 0, "\n"; # this should not exist
EXPECT
1
2
0
4
5
6
7
8
0
########
#
# NAME FETCH freeing tie'd SV still works
sub TIESCALAR { bless [] }
sub FETCH { *a = \1; 2 }
tie $a, 'main';
print $a;
EXPECT
2
########

# NAME [20020716.007 (#10080)] - nested FETCHES

sub F1::TIEARRAY { bless [], 'F1' }
sub F1::FETCH { 1 }
my @f1;
tie @f1, 'F1';

sub F2::TIEARRAY { bless [2], 'F2' }
sub F2::FETCH { my $self = shift; my $x = $f1[3]; $self }
my @f2;
tie @f2, 'F2';

print $f2[4][0],"\n";

sub F3::TIEHASH { bless [], 'F3' }
sub F3::FETCH { 1 }
my %f3;
tie %f3, 'F3';

sub F4::TIEHASH { bless [3], 'F4' }
sub F4::FETCH { my $self = shift; my $x = $f3{3}; $self }
my %f4;
tie %f4, 'F4';

print $f4{'foo'}[0],"\n";

EXPECT
2
3
########
# NAME test untie() from within FETCH
package Foo;
sub TIESCALAR { my $pkg = shift; return bless [@_], $pkg; }
sub FETCH {
  my $self = shift;
  my ($obj, $field) = @$self;
  untie $obj->{$field};
  $obj->{$field} = "Bar";
}
package main;
tie $a->{foo}, "Foo", $a, "foo";
my $s = $a->{foo}; # access once
# the hash element should not be tied anymore
print defined tied $a->{foo} ? "not ok" : "ok";
EXPECT
ok
########
# NAME the tmps returned by FETCH should appear to be SCALAR
# (even though they are now implemented using PVLVs.)
package X;
sub TIEHASH { bless {} }
sub TIEARRAY { bless {} }
sub FETCH {1}
my (%h, @a);
tie %h, 'X';
tie @a, 'X';
my $r1 = \$h{1};
my $r2 = \$a[0];
my $s = "$r1 ". ref($r1) . " $r2 " . ref($r2);
$s=~ s/\(0x\w+\)//g;
print $s, "\n";
EXPECT
SCALAR SCALAR SCALAR SCALAR
########
# NAME [perl #23287] segfault in untie
no warnings;
sub TIESCALAR { bless $_[1], $_[0] }
my $var;
tie $var, 'main', \$var;
untie $var;
EXPECT
########
# NAME Test case from perlmonks by runrig
# http://www.perlmonks.org/index.pl?node_id=273490
# "Here is what I tried. I think its similar to what you've tried
#  above. Its odd but convenient that after untie'ing you are left with
#  a variable that has the same value as was last returned from
#  FETCH. (At least on my perl v5.6.1). So you don't need to pass a
#  reference to the variable in order to set it after the untie (here it
#  is accessed through a closure)."
use strict;
use warnings;
package MyTied;
sub TIESCALAR {
    my ($class,$code) = @_;
    bless $code, $class;
}
sub FETCH {
    my $self = shift;
    print "Untie\n";
    $self->();
}
package main;
my $var;
tie $var, 'MyTied', sub { untie $var; 4 };
print "One\n";
print "$var\n";
print "Two\n";
print "$var\n";
print "Three\n";
print "$var\n";
EXPECT
One
Untie
4
Two
4
Three
4
########

# NAME [perl #22297] cannot untie scalar from within tied FETCH
my $counter = 0;
my $x = 7;
my $ref = \$x;
tie $x, 'Overlay', $ref, $x;
my $y;
$y = $x;
$y = $x;
$y = $x;
$y = $x;
#print "WILL EXTERNAL UNTIE $ref\n";
untie $$ref;
$y = $x;
$y = $x;
$y = $x;
$y = $x;
#print "counter = $counter\n";

print (($counter == 1) ? "ok\n" : "not ok\n");

package Overlay;

sub TIESCALAR
{
        my $pkg = shift;
        my ($ref, $val) = @_;
        return bless [ $ref, $val ], $pkg;
}

sub FETCH
{
        my $self = shift;
        my ($ref, $val) = @$self;
        #print "WILL INTERNAL UNITE $ref\n";
        $counter++;
        untie $$ref;
        return $val;
}
EXPECT
ok
########

# NAME [perl #948] cannot meaningfully tie $,
package TieDollarComma;
no warnings;
sub TIESCALAR {
     my $pkg = shift;
     return bless \my $x, $pkg;
}

sub STORE {
    my $self = shift;
    $$self = shift;
    print "STORE set '$$self'\n";
}

sub FETCH {
    my $self = shift;
    print "<FETCH>";
    return $$self;
}
package main;

tie $,, 'TieDollarComma';
$, = 'BOBBINS';
print "join", "things", "up\n";
EXPECT
STORE set 'BOBBINS'
join<FETCH>BOBBINSthings<FETCH>BOBBINSup
########

# NAME test SCALAR method
package TieScalar;

sub TIEHASH {
    my $pkg = shift;
    bless { } => $pkg;
}

sub STORE {
    $_[0]->{$_[1]} = $_[2];
}

sub FETCH {
    $_[0]->{$_[1]}
}

sub CLEAR {
    %{ $_[0] } = ();
}

sub SCALAR {
    print "SCALAR\n";
    return 0 if ! keys %{$_[0]};
    sprintf "%i/%i", scalar keys %{$_[0]}, scalar keys %{$_[0]};
}

package main;
tie my %h => "TieScalar";
$h{key1} = "val1";
$h{key2} = "val2";
print scalar %h, "\n"
    if %h; # this should also call SCALAR but implicitly
%h = ();
print scalar %h, "\n"
    if !%h; # this should also call SCALAR but implicitly
EXPECT
SCALAR
SCALAR
2/2
SCALAR
SCALAR
0
########

# test scalar on tied hash when no SCALAR method has been given
package TieScalar;

sub TIEHASH {
    my $pkg = shift;
    bless { } => $pkg;
}
sub STORE {
    $_[0]->{$_[1]} = $_[2];
}
sub FETCH {
    $_[0]->{$_[1]}
}
sub CLEAR {
    %{ $_[0] } = ();
}
sub FIRSTKEY {
    my $a = keys %{ $_[0] };
    print "FIRSTKEY\n";
    each %{ $_[0] };
}

package main;
tie my %h => "TieScalar";

if (!%h) {
    print "empty\n";
} else {
    print "not empty\n";
}

$h{key1} = "val1";
print "not empty\n" if %h;
print "not empty\n" if %h;
print "-->\n";
my ($k,$v) = each %h;
print "<--\n";
print "not empty\n" if %h;
%h = ();
print "empty\n" if ! %h;
EXPECT
FIRSTKEY
empty
FIRSTKEY
not empty
FIRSTKEY
not empty
-->
FIRSTKEY
<--
not empty
FIRSTKEY
empty
########
sub TIESCALAR { bless {} }
sub FETCH { my $x = 3.3; 1 if 0+$x; $x }
tie my $h, "main";
print $h,"\n";
EXPECT
3.3
########
sub TIESCALAR { bless {} }
sub FETCH { shift()->{i} ++ }
tie my $h, "main";
print $h.$h;
EXPECT
01
########
# SKIP ? $IS_EBCDIC
# skipped on EBCDIC because "2" | "8" is 0xFA (not COLON as it is on ASCII),
# which isn't representable in this file's UTF-8 encoding.
# NAME Bug 53482 (and maybe others)
use p5;
sub TIESCALAR { my $foo = $_[1]; bless \$foo, $_[0] }
sub FETCH { ${$_[0]} }
tie my $x1, "main", 2;
tie my $y1, "main", 8;
print $x1 | $y1;
print $x1 | $y1;
tie my $x2, "main", "2";
tie my $y2, "main", "8";
print $x2 | $y2;
print $x2 | $y2;
EXPECT
1010::
########
# NAME Bug 36267
sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }
my %h;
$h{b}=1;
delete $h{b};
print scalar keys %h, "\n";
tie %h, 'main';
my %i;
$i{a}=1;
%h = %i;
untie %h;
print scalar keys %h, "\n";
EXPECT
0
0
########
# NAME Bug 37731
sub foo::TIESCALAR { bless {value => $_[1]}, $_[0] }
sub foo::FETCH { $_[0]->{value} }
tie my $VAR, 'foo', '42';
foreach my $var ($VAR) {
    print +($var eq $VAR) ? "yes\n" : "no\n";
}
EXPECT
yes
########
# NAME tie @a
our @a;
sub TIEARRAY { bless [], 'main' }
{
    local @a;
    tie @a, 'main';
}
print "tied\n" if tied @a;
EXPECT
########
# NAME tie %h
our %h;
sub TIEHASH { bless [], 'main' }
{
    local %h;
    tie %h, 'main';
}
print "tied\n" if tied %h;
EXPECT
########
# NAME RT 20727: PL_defoutgv is left as a tied element
sub TIESCALAR { return bless {}, 'main' }

sub STORE {
    select($_[1]);
    $_[1] = 1;
    select(); # this used to coredump or assert fail
}
tie my $SELECT, 'main';
$SELECT = *STDERR;
EXPECT
########
# NAME RT 23810: eval in die in FETCH can corrupt context stack

no strict; no warnings;
my $file = 'rt23810.pm';

my $e;
my $s;

sub do_require {
    my ($str, $eval) = @_;
    open my $fh, '>', $file or die "Can't create $file: $!\n";
    print $fh $str;
    close $fh;
    if ($eval) {
	$s .= '-ERQ';
	eval { require $pm; $s .= '-ENDE' }
    }
    else {
	$s .= '-RQ';
	require $pm;
    }
    $s .= '-ENDRQ';
    unlink $file;
}

sub TIEHASH { bless {} }

sub FETCH {
    # 10 or more syntax errors makes yyparse croak()
    my $bad = q{$x+;$x+;$x+;$x+;$x+;$x+;$x+;$x+;$x+$x+;$x+;$x+;$x+;$x+;;$x+;};

    if ($_[1] eq 'eval') {
	$s .= 'EVAL';
	eval q[BEGIN { die; $s .= '-X1' }];
	$s .= '-BD';
	eval q[BEGIN { $x+ }];
	$s .= '-BS';
	eval '$x+';
	$s .= '-E1';
	$s .= '-S1' while $@ =~ /syntax error at/g;
	eval $bad;
	$s .= '-E2';
	$s .= '-S2' while $@ =~ /syntax error at/g;
    }
    elsif ($_[1] eq 'require') {
	$s .= 'REQUIRE';
	my @text = (
	    q[BEGIN { die; $s .= '-X1' }],
	    q[BEGIN { $x+ }],
	    '$x+',
	    $bad
	);
	for my $i (0..$#text) {
	    $s .= "-$i";
	    do_require($txt[$i], 0) if $e;;
	    do_require($txt[$i], 1);
	}
    }
    elsif ($_[1] eq 'exit') {
	eval q[exit(0); print "overshot eval\n"];
    }
    else {
	print "unknown key: '$_[1]'\n";
    }
    return "-R";
}
my %foo;
tie %foo, "main";

for my $action(qw(eval require)) {
    $s = ''; $e = 0; $s .= main->FETCH($action); print "$action: s0=$s\n";
    $s = ''; $e = 1; eval { $s .= main->FETCH($action)}; print "$action: s1=$s\n";
    $s = ''; $e = 0; $s .= $foo{$action}; print "$action: s2=$s\n";
    $s = ''; $e = 1; eval { $s .= $foo{$action}}; print "$action: s3=$s\n";
}
1 while unlink $file;

$foo{'exit'};
print "overshot main\n"; # shouldn't reach here

EXPECT
eval: s0=EVAL-BD-BS-E1-S1-E2-S2-S2-S2-S2-S2-S2-S2-S2-S2-S2-R
eval: s1=EVAL-BD-BS-E1-S1-E2-S2-S2-S2-S2-S2-S2-S2-S2-S2-S2-R
eval: s2=EVAL-BD-BS-E1-S1-E2-S2-S2-S2-S2-S2-S2-S2-S2-S2-S2-R
eval: s3=EVAL-BD-BS-E1-S1-E2-S2-S2-S2-S2-S2-S2-S2-S2-S2-S2-R
require: s0=REQUIRE-0-ERQ-ENDRQ-1-ERQ-ENDRQ-2-ERQ-ENDRQ-3-ERQ-ENDRQ-R
require: s1=REQUIRE-0-RQ
require: s2=REQUIRE-0-ERQ-ENDRQ-1-ERQ-ENDRQ-2-ERQ-ENDRQ-3-ERQ-ENDRQ-R
require: s3=REQUIRE-0-RQ
########
# NAME RT 8857: STORE incorrectly invoked for local($_) on aliased tied array
#          element

no warnings;

sub TIEARRAY { bless [], $_[0] }
sub TIEHASH  { bless [], $_[0] }
sub FETCH { $_[0]->[$_[1]] }
sub STORE { $_[0]->[$_[1]] = $_[2] }


sub f {
    local $_[0];
}
tie my @a, 'main';
tie my %h, 'main';

foreach ($a[0], $h{a}) {
    f($_);
}
# on failure, chucks up 'premature free' etc messages
EXPECT
########
# NAME RT 5475:
# the initial fix for this bug caused tied scalar FETCH to be called
# multiple times when that scalar was an element in an array. Check it
# only gets called once now.

sub TIESCALAR { bless [], $_[0] }
my $c = 0;
sub FETCH { $c++; 0 }
sub FETCHSIZE { 1 }
sub STORE { $c += 100; 0 }


my (@a, %h);
tie $a[0],   'main';
tie $h{foo}, 'main';

my $i = 0;
my $x = $a[0] + $h{foo} + $a[$i] + (@a)[0];
print "x=$x c=$c\n";
EXPECT
x=0 c=4
########
# Bug 68192 - numeric ops not calling mg_get when tied scalar holds a ref
sub TIESCALAR { bless {}, __PACKAGE__ };
sub STORE {};
sub FETCH {
 print "fetching... "; # make sure FETCH is called once per op
 123456
};
my $foo;
tie $foo, __PACKAGE__;
my $a = [1234567];
$foo = $a;
print "+   ", 0 + $foo, "\n";
print "**  ", $foo**1, "\n";
print "*   ", $foo*1, "\n";
print "/   ", $foo*1, "\n";
print "%   ", $foo%123457, "\n";
print "-   ", $foo-0, "\n";
print "neg ", - -$foo, "\n";
print "int ", int $foo, "\n";
print "abs ", abs $foo, "\n";
print "==  ", 123456 == $foo, "\n";
print "<   ", 123455 < $foo, "\n";
print ">   ", 123457 > $foo, "\n";
print "<=  ", 123456 <= $foo, "\n";
print ">=  ", 123456 >= $foo, "\n";
print "!=  ", 0 != $foo, "\n";
print "<=> ", 123457 <=> $foo, "\n";
EXPECT
fetching... +   123456
fetching... **  123456
fetching... *   123456
fetching... /   123456
fetching... %   123456
fetching... -   123456
fetching... neg 123456
fetching... int 123456
fetching... abs 123456
fetching... ==  1
fetching... <   1
fetching... >   1
fetching... <=  1
fetching... >=  1
fetching... !=  1
fetching... <=> 1
########
# NAME Ties returning overloaded objects
no strict 'subs'; no warnings;
{
 package overloaded;
 use overload
  '*{}' => sub { print '*{}'; \*100 },
  '@{}' => sub { print '@{}'; \@100 },
  '%{}' => sub { print '%{}'; \%100 },
  '${}' => sub { print '${}'; \$100 },
  map {
   my $op = $_;
   $_ => sub { print "$op"; 100 }
  } qw< 0+ "" + ** * / % - neg int abs == < > <= >= != <=> <> >
}
my $o = bless [], overloaded;

sub TIESCALAR { bless {}, "" }
sub FETCH { print "fetching... "; $o }
sub STORE{}
tie my $ghew, "";
my (@spled, %frit, $drile);
$ghew=undef; 1+$ghew; print "\n";
$ghew=undef; $ghew**1; print "\n";
$ghew=undef; $ghew*1; print "\n";
$ghew=undef; $ghew/1; print "\n";
$ghew=undef; $ghew%1; print "\n";
$ghew=undef; $ghew-1; print "\n";
$ghew=undef; -$ghew; print "\n";
$ghew=undef; int $ghew; print "\n";
$ghew=undef; abs $ghew; print "\n";
$ghew=undef; 1 == $ghew; print "\n";
$ghew=undef; $ghew<1; print "\n";
$ghew=undef; $ghew>1; print "\n";
$ghew=undef; $ghew<=1; print "\n";
$ghew=undef; $ghew >=1; print "\n";
$ghew=undef; $ghew != 1; print "\n";
$ghew=undef; $ghew<=>1; print "\n";
$ghew=undef; <$ghew>; print "\n";
$ghew=\*shrext; *$ghew; print "\n";
$ghew=\@spled; @$ghew; print "\n";
$ghew=\%frit; %$ghew; print "\n";
$ghew=\$drile; $$ghew; print "\n";
EXPECT
fetching... +
fetching... **
fetching... *
fetching... /
fetching... %
fetching... -
fetching... neg
fetching... int
fetching... abs
fetching... ==
fetching... <
fetching... >
fetching... <=
fetching... >=
fetching... !=
fetching... <=>
fetching... <>
fetching... *{}
fetching... @{}
fetching... %{}
fetching... ${}
########
# NAME RT 51636: segmentation fault with array ties

tie my @a, 'T';
@a = (1);
print "ok\n"; # if we got here we didn't crash

package T;

sub TIEARRAY { bless {} }
sub STORE    { tie my @b, 'T' }
sub CLEAR    { }
sub EXTEND   { }

EXPECT
ok
########
# NAME RT 8438: Tied scalars don't call FETCH when subref is dereferenced

sub TIESCALAR { bless {} }

my $fetch = 0;
my $called = 0;
sub FETCH { $fetch++; sub { $called++ } }

tie my $f, 'main';
$f->(1) for 1,2;
print "fetch=$fetch\ncalled=$called\n";

EXPECT
fetch=2
called=2
########
# NAME tie mustn't attempt to call methods on bareword filehandles.
no warnings qw{ once uninitialized };
sub IO::File::TIEARRAY {
    die "Did not want to invoke IO::File::TIEARRAY";
}
my $x = fileno FOO; tie my @a, "FOO"
EXPECT
Can't locate object method "TIEARRAY" via package "FOO" (perhaps you forgot to load "FOO"?) at - line 5.
########
# NAME tie into empty package name
tie my $foo, "";
EXPECT
Can't locate object method "TIESCALAR" via package "main" at - line 1.
########
# NAME tie into undef package name
no warnings "uninitialized";
tie my $foo, undef;
EXPECT
Can't locate object method "TIESCALAR" via package "main" at - line 2.
########
# NAME tie into nonexistent glob [RT#130623 assertion failure]
no warnings 'once';
tie my $foo, *FOO;
EXPECT
Can't locate object method "TIESCALAR" via package "FOO" at - line 2.
########
# NAME tie into glob when package exists but not method: no "*", no "main::"
no warnings 'once';
{ package PackageWithoutTIESCALAR }
tie my $foo, *PackageWithoutTIESCALAR;
EXPECT
Can't locate object method "TIESCALAR" via package "PackageWithoutTIESCALAR" at - line 3.
########
# NAME tie into reference [RT#130623 assertion failure]
eval { tie my $foo, \"nope" };
my $exn = $@ // "";
print $exn =~ s/0x\w+/0xNNN/rg;
EXPECT
Can't locate object method "TIESCALAR" via package "SCALAR(0xNNN)" at - line 1.
########
#
# NAME STORE freeing tie'd AV
no warnings 'once';
my @a;
sub TIEARRAY  { bless [] }
sub STORE     { *a = []; 1 }
sub STORESIZE { }
sub EXTEND    { }
tie @a, 'main';
$a[0] = 1;
EXPECT
########
#
# NAME CLEAR freeing tie'd AV
no warnings 'once';
my @a;
sub TIEARRAY  { bless [] }
sub CLEAR     { *a = []; 1 }
sub STORESIZE { }
sub EXTEND    { }
sub STORE     { }
tie @a, 'main';
@a = (1,2,3);
EXPECT
########
#
# NAME FETCHSIZE freeing tie'd AV
no warnings 'once';
my @a;
sub TIEARRAY  { bless [] }
sub FETCHSIZE { *a = []; 100 }
sub STORESIZE { }
sub EXTEND    { }
sub STORE     { }
tie @a, 'main';
print $#a,"\n"
EXPECT
99
########
#
# NAME [perl #86328] Crash when freeing tie magic that can increment the refcnt
no warnings 'once';
eval { require Scalar::Util } or print("ok\n"), exit;

sub TIEHASH {
    return $_[1];
}
*TIEARRAY = *TIEHASH;

sub DESTROY {
    my ($tied) = @_;
    my $b = $tied->[0];
}

my $a = {};
my $o = bless [];
Scalar::Util::weaken($o->[0] = $a);
tie %$a, "main", $o;

my $b = [];
my $p = bless [];
Scalar::Util::weaken($p->[0] = $b);
tie @$b, "main", $p;

# Done setting up the evil data structures

$a = undef;
$b = undef;
print "ok\n";

EXPECT
ok
########
#
# NAME Localising a tied COW scalar should not make it read-only.

sub TIESCALAR { bless [] }
sub FETCH { __PACKAGE__ }
sub STORE {}
tie our $x, "";
my $void = "$x";
{
    local $x;
    $x = 3;
}
print "ok\n";
EXPECT
ok
########
#
# NAME Nor should it be impossible to tie COW scalars that are already PVMGs.

sub TIESCALAR { bless [] }
my $x = *foo;        # PVGV
undef $x;         # downgrade to PVMG
$x = __PACKAGE__; # PVMG + COW
tie $x, "";       # bang!

print STDERR "ok\n";

# However, one should not be able to tie read-only glob copies, which look
# a bit like kine internally (FAKE + READONLY).
my $y = *foo;
Internals::SvREADONLY($y,1);
tie $y, "";

EXPECT
ok
Modification of a read-only value attempted at - line 15.
########
#
# NAME And one should not be able to tie read-only COWs
for(__PACKAGE__) { tie $_, "" }
sub TIESCALAR {bless []}
EXPECT
Modification of a read-only value attempted at - line 2.
########

# NAME Similarly, read-only regexps cannot be tied.
sub TIESCALAR { bless [] }
my $y = ${qr//};
Internals::SvREADONLY($y,1);
tie $y, "";

EXPECT
Modification of a read-only value attempted at - line 5.
########
no strict 'subs'; no warnings;
# NAME tied() should still work on tied scalars after glob assignment
sub TIESCALAR {bless[]}
sub FETCH {*foo}
sub f::TIEHANDLE{bless[],f}
tie *foo, "f";
tie my $rin, "";
[$rin]; # call FETCH
print ref tied $rin, "\n";
print ref tied *$rin, "\n";
EXPECT
main
f
########

# NAME (un)tie $glob_copy vs (un)tie *$glob_copy
sub TIESCALAR { print "TIESCALAR\n"; bless [] }
sub TIEHANDLE{ print "TIEHANDLE\n"; bless [] }
sub FETCH { print "never called\n" }
my $f = *foo;
tie *$f, "";
tie $f, "";
untie $f;
print "ok 1\n" if !tied $f;
() = $f; # should not call FETCH
untie *$f;
print "ok 2\n" if !tied *foo;
EXPECT
TIEHANDLE
TIESCALAR
ok 1
ok 2
########

# NAME RT #8611 mustn't goto outside the magic stack - a
#
sub TIESCALAR { warn "tiescalar\n"; bless [] }
sub FETCH { warn "fetch()\n"; goto FOO; }
tie my $f, "";
warn "before fetch\n";
my $a = "$f";
warn "before FOO\n";
FOO:
warn "after FOO\n";
EXPECT
tiescalar
before fetch
fetch()
Can't find label FOO at - line 4.
########

# NAME RT #8611 mustn't goto outside the magic stack - b
sub TIEHANDLE { warn "tiehandle\n"; bless [] }
sub PRINT { warn "print()\n"; goto FOO; }
tie *F, "";
warn "before print\n";
print F "abc";
warn "before FOO\n";
FOO:
warn "after FOO\n";
EXPECT
tiehandle
before print
print()
Can't find label FOO at - line 3.
########

# NAME \&$tied with $tied holding a reference before the fetch (but not after)
no warnings;
sub ::72 { 73 };
sub TIESCALAR {bless[]}
sub STORE{}
sub FETCH { 72 }
my $y;
tie my $x, "main";
$x = \$y;
\&$x;
print "ok\n";
EXPECT
ok
########

# NAME tied with tied holding a PVLV glob before the fetch (but not after)
# \&$tied with $tied holding a PVLV glob before the fetch (but not after)
no warnings 'once';
sub ::72 { 73 };
sub TIEARRAY {bless[]}
sub STORE{}
sub FETCH { 72 }
tie my @x, "main";
my $elem = \$x[0];
$$elem = *bar;
print &{\&$$elem}, "\n";
EXPECT
73
########

# NAME tied with tied holding a PVGV glob before the fetch (but not after) 
# \&$tied with $tied holding a PVGV glob before the fetch (but not after)
no warnings 'once';
local *72 = sub { 73 };
sub TIESCALAR {bless[]}
sub STORE{}
sub FETCH { 72 }
tie my $x, "main";
$x = *bar;
print &{\&$x}, "\n";
EXPECT
73
########

# NAME Lexicals should not be visible to magic methods on scope exit
BEGIN { unless (defined &DynaLoader::boot_DynaLoader) {
    print "HASH\nHASH\nARRAY\nARRAY\n"; exit;
}}
use Scalar::Util 'weaken';
{ package xoufghd;
  sub TIEHASH { Scalar::Util::weaken($_[1]); bless \$_[1], xoufghd:: }
  no warnings 'once';
  *TIEARRAY = *TIEHASH;
  DESTROY {
     bless ${$_[0]} || return, 0;
} }
no warnings 'once';
our $ref;
for my $sub (
    # hashes: ties before backrefs
    sub {
        my %hash;
        $ref = ref \%hash;
        tie %hash, xoufghd::, \%hash;
        1;
    },
    # hashes: backrefs before ties
    sub {
        my %hash;
        $ref = ref \%hash;
        weaken(my $x = \%hash);
        tie %hash, xoufghd::, \%hash;
        1;
    },
    # arrays: ties before backrefs
    sub {
        my @array;
        $ref = ref \@array;
        tie @array, xoufghd::, \@array;
        1;
    },
    # arrays: backrefs before ties
    sub {
        my @array;
        $ref = ref \@array;
        weaken(my $x = \@array);
        tie @array, xoufghd::, \@array;
        1;
    },
) {
    &$sub;
    &$sub;
    print $ref, "\n";
}
EXPECT
HASH
HASH
ARRAY
ARRAY
########

# NAME Localising a tied variable with a typeglob in it should copy magic
no warnings 'once';
sub TIESCALAR{bless[]}
sub FETCH{warn "fetching\n"; *foo}
sub STORE{}
our $x;
tie $x, "";
local $x;
warn "before";
my $void = "$x";
warn "after";
EXPECT
fetching
before at - line 9.
fetching
after at - line 11.
########

# NAME tied returns same value as tie
sub TIESCALAR{bless[]}
my ($tyre, $tied);
$tyre = \tie $tied, "";
print "ok\n" if \tied $tied == $tyre;
EXPECT
ok
########

# tied arrays should always be AvREAL
$^W=1;
sub TIEARRAY{bless[]}
sub {
  tie @_, "";
  \@_; # used to produce: av_reify called on tied array at - line 7.
}->(1);
EXPECT
########

# [perl #67490] scalar-tying elements of magic hashes
sub TIESCALAR{bless[]}
sub STORE{}
tie $ENV{foo}, '';
$ENV{foo} = 78;
delete $ENV{foo};
tie $^H{foo}, '';
$^H{foo} = 78;
delete $^H{foo};
EXPECT
########

# [perl #35865, #43011] autovivification should call FETCH after STORE
# because perl does not know that the FETCH would have returned the same
# thing that was just stored.

# This package never likes to take ownership of other people’s refs.  It
# always makes its own copies.  (For simplicity, it only accepts hashes.)
package copier {
    sub TIEHASH { bless {} }
    sub FETCH   { $_[0]{$_[1]} }
    sub STORE   { $_[0]{$_[1]} = { %{ $_[2] } } }
}
tie my %h, copier::;
$h{i}{j} = 'k';
print $h{i}{j}, "\n";
EXPECT
k
########

# NAME [perl #8931]
# [perl #8931] FETCH for tied $" called an odd number of times.
use strict;
my $i = 0;
sub A::TIESCALAR {bless [] => 'A'}
sub A::FETCH {print ++ $i, "\n"}
my @a = ("", "", "");

tie $" => 'A';
my $xx = "@a";

$i = 0;
tie my $a => 'A';
my $void = join $a, 1..10;
EXPECT
1
1
########

# NAME [perl #9391]
# [perl #9391] return value from 'tied' not discarded soon enough
use warnings;
tie my @a, 'T';
if (tied @a) {
untie @a;
}

sub T::TIEARRAY { my $s; bless \$s => "T" }
EXPECT
########

# NAME Test that tying a hash does not leak a deleted iterator
# This produced unbalanced string table warnings under
# PERL_DESTRUCT_LEVEL=2.
package l {
    sub TIEHASH{bless[]}
}
my $h = {foo=>0};
each %$h;
delete $$h{foo};
tie %$h, 'l';
EXPECT
########
no strict; no warnings;
# NAME EXISTS on arrays
sub TIEARRAY{bless[]};
sub FETCHSIZE { 50 }
sub EXISTS { print "does $_[1] exist?\n" }
tie my @a, "";
exists $a[1];
exists $a[-1];
$NEGATIVE_INDICES=1;
exists $a[-1];
EXPECT
does 1 exist?
does 49 exist?
does -1 exist?
########

# Crash when using negative index on array tied to non-object
sub TIEARRAY{bless[]};
my @a; ${\tie @a, ""} = undef;
eval { $_ = $a[-1] }; print $@;
eval { $a[-1] = '' }; print $@;
eval { delete $a[-1] }; print $@;
eval { exists $a[-1] }; print $@;

EXPECT
Can't call method "FETCHSIZE" on an undefined value at - line 5.
Can't call method "FETCHSIZE" on an undefined value at - line 6.
Can't call method "FETCHSIZE" on an undefined value at - line 7.
Can't call method "FETCHSIZE" on an undefined value at - line 8.
########

# Crash when reading negative index when NEGATIVE_INDICES stub exists
sub NEGATIVE_INDICES;
sub TIEARRAY{bless[]};
sub FETCHSIZE{}
my @a;
no warnings "uninitialized";
tie @a, "";
print "ok\n" if ! defined $a[-1];
EXPECT
ok
########

# Assigning vstrings to tied scalars
sub TIESCALAR{bless[]};
sub STORE { print ref \$_[1], "\n" }
tie my $x, ""; $x = v3;
EXPECT
VSTRING
########

# [perl #27010] Tying deferred elements
$\="\n";
sub TIESCALAR{bless[]};
my %h;
sub {
    tie $_[0], "";
    print ref tied $h{k};
    tie $h{l}, "";
    print ref tied $_[1];
    untie $h{k};
    print tied $_[0] // 'undef';
    untie $_[1];
    print tied $h{l} // 'undef';
    # check that tied and untie do not autovivify
    # XXX should they autovivify?
    tied $_[2];
    print exists $h{m} ? "yes" : "no";
    untie $_[2];
    print exists $h{m} ? "yes" : "no";
}->($h{k}, $h{l}, $h{m});
EXPECT
main
main
undef
undef
no
no
########
no warnings "uninitialized";
# [perl #78194] Passing op return values to tie constructors
sub TIEARRAY{
    print \$_[1] == \$_[1] ? "ok\n" : "not ok\n";
};
tie my @a, "", "$a$b";
EXPECT
ok
########
no strict 'subs';
# Scalar-tied locked hash keys and copy-on-write
use Tie::Scalar;
my %h;
tie $h{foo}, Tie::StdScalar;
tie $h{bar}, Tie::StdScalar;
$h{foo} = __PACKAGE__; # COW
$h{bar} = 1;       # not COW
# Moral equivalent of Hash::Util::lock_whatever, but miniperl-compatible
Internals::SvREADONLY($h{foo},1);
Internals::SvREADONLY($h{bar},1);
print $h{foo}, "\n"; # should not croak
# Whether the value is COW should make no difference here (whether the
# behaviour is ultimately correct is another matter):
local $h{foo};
local $h{bar};
print "ok\n" if (eval{ $h{foo} = 1 }||$@) eq (eval{ $h{bar} = 1 }||$@);
EXPECT
main
ok
########
# SKIP ? $::IS_EBCDIC
# skipped on EBCDIC because different from ASCII and results vary depending on
# code page

# &xsub and goto &xsub with tied @_
use Tie::Array;
no strict 'subs';
tie @_, Tie::StdArray;
@_ = "\xff";
&utf8::encode;
printf "%x\n", $_ for map ord, split //, $_[0];
print "--\n";
@_ = "\xff";
& {sub { goto &utf8::encode }};
printf "%x\n", $_ for map ord, split //, $_[0];
EXPECT
c3
bf
--
c3
bf
########

# Defelem pointing to nonexistent element of tied array

use Tie::Array;
# This sub is called with a deferred element.  Inside the sub, $_[0] pros-
# pectively points to element 10000 of @a.
my @a;
sub {
  tie @a, "Tie::StdArray";  # now @a is tied
  $#a = 20000;  # and FETCHSIZE/AvFILL will now return a big number
  $a[10000] = "crumpets\n";
  $_ = "$_[0]"; # but defelems don't expect tied arrays and try to read
                # AvARRAY[10000], which crashes
}->($a[10000]);
print
EXPECT
crumpets
########
no warnings;
# tied() in list assignment

sub TIESCALAR : lvalue {
    ${+pop} = bless [], shift;
}
tie my $t, "", \$a;
$a = 7;
($a, $b) = (3, tied $t);
print "a is $a\n";
print "b is $b\n";
EXPECT
a is 3
b is 7
########
# when assigning to array/hash, ensure get magic is processed first
use Tie::Hash;
my %tied;
tie %tied, "Tie::StdHash";
%tied = qw(a foo);
my @a = values %tied;
%tied = qw(b bar); # overwrites @a's contents unless magic was called
print "$a[0]\n";
my %h = ("x", values %tied);
%tied = qw(c baz); # overwrites @a's contents unless magic was called
print "$h{x}\n";

EXPECT
foo
bar
########
# keys(%tied) in bool context without SCALAR present
my ($f,$n) = (0,0);
my %inner = (a =>1, b => 2, c => 3);
sub TIEHASH  { bless \%inner, $_[0] }
sub FIRSTKEY { $f++; my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { $n++; each %{$_[0]} }
tie my %h, 'main';
my $x = !keys %h;
print "[$x][$f][$n]\n";
%inner = ();
$x = !keys %h;
print "[$x][$f][$n]\n";
EXPECT
[][1][0]
[1][2][0]
########
# keys(%tied) in bool context with SCALAR present
my ($f,$n, $s) = (0,0,0);
my %inner = (a =>1, b => 2, c => 3);
sub TIEHASH  { bless \%inner, $_[0] }
sub FIRSTKEY { $f++; my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { $n++; each %{$_[0]} }
sub SCALAR   { $s++; scalar %{$_[0]} }
tie my %h, 'main';
my $x = !keys %h;
print "[$x][$f][$n][$s]\n";
%inner = ();
$x = !keys %h;
print "[$x][$f][$n][$s]\n";
EXPECT
[][0][0][1]
[1][0][0][2]
########
# keys(%tied) in scalar context without SCALAR present
my ($f,$n) = (0,0);
my %inner = (a =>1, b => 2, c => 3);
sub TIEHASH  { bless \%inner, $_[0] }
sub FIRSTKEY { $f++; my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { $n++; each %{$_[0]} }
tie my %h, 'main';
my $x = keys %h;
print "[$x][$f][$n]\n";
%inner = ();
$x = keys %h;
print "[$x][$f][$n]\n";
EXPECT
[3][1][3]
[0][2][3]
########
# keys(%tied) in scalar context with SCALAR present
# XXX the behaviour of scalar(keys(%tied)) may change - it currently
# doesn't make use of SCALAR() if present
my ($f,$n, $s) = (0,0,0);
my %inner = (a =>1, b => 2, c => 3);
sub TIEHASH  { bless \%inner, $_[0] }
sub FIRSTKEY { $f++; my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { $n++; each %{$_[0]} }
sub SCALAR   { $s++; scalar %{$_[0]} }
tie my %h, 'main';
my $x = keys %h;
print "[$x][$f][$n][$s]\n";
%inner = ();
$x = keys %h;
print "[$x][$f][$n][$s]\n";
EXPECT
[3][1][3][0]
[0][2][3][0]
########
# dying while doing a SAVEt_DELETE dureing scope exit leaked a copy of the
# key. Give ASan something to play with
sub TIEHASH { bless({}, $_[0]) }
sub EXISTS { 0 }
sub DELETE { die; }
sub DESTROY { print "destroy\n"; }

eval {
    my %h;
    tie %h, "main";
    local $h{foo};
    print "leaving\n";
};
print "left\n";
EXPECT
leaving
destroy
left
########
# ditto for SAVEt_DELETE with an array
sub TIEARRAY { bless({}, $_[0]) }
sub EXISTS { 0 }
sub DELETE { die; }
sub DESTROY { print "destroy\n"; }

eval {
    my @a;
    tie @a, "main";
    delete local $a[0];
    print "leaving\n";
};
print "left\n";
EXPECT
leaving
destroy
left
