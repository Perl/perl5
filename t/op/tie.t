#!./perl

# This test harness will (eventually) test the "tie" functionality
# without the need for a *DBM* implementation.

# Currently it only tests the untie warning 

chdir 't' if -d 't';
@INC = '../lib';
$ENV{PERL5LIB} = "../lib";

$|=1;

# catch warnings into fatal errors
$SIG{__WARN__} = sub { die "WARNING: @_" } ;
$SIG{__DIE__}  = sub { die @_ };

undef $/;
@prgs = split "\n########\n", <DATA>;
print "1..", scalar @prgs, "\n";

for (@prgs){
    my($prog,$expected) = split(/\nEXPECT\n/, $_);
    eval "$prog" ;
    $status = $?;
    $results = $@ ;
    $results =~ s/\n+$//;
    $expected =~ s/\n+$//;
    if ( $status or $results and $results !~ /^(WARNING: )?$expected/){
	print STDERR "STATUS: $status\n";
	print STDERR "PROG: $prog\n";
	print STDERR "EXPECTED:\n$expected\n";
	print STDERR "GOT:\n$results\n";
	print "not ";
    }
    print "ok ", ++$i, "\n";
}

__END__

# standard behaviour, without any extra references
use Tie::Hash ;
tie %h, Tie::StdHash;
untie %h;
EXPECT
########

# standard behaviour, without any extra references
use Tie::Hash ;
{package Tie::HashUntie;
 use base 'Tie::StdHash';
 sub UNTIE
  {
   warn "Untied\n";
  }
}
tie %h, Tie::HashUntie;
untie %h;
EXPECT
Untied
########

# standard behaviour, with 1 extra reference
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
untie %h;
EXPECT
########

# standard behaviour, with 1 extra reference via tied
use Tie::Hash ;
tie %h, Tie::StdHash;
$a = tied %h;
untie %h;
EXPECT
########

# standard behaviour, with 1 extra reference which is destroyed
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
$a = 0 ;
untie %h;
EXPECT
########

# standard behaviour, with 1 extra reference via tied which is destroyed
use Tie::Hash ;
tie %h, Tie::StdHash;
$a = tied %h;
$a = 0 ;
untie %h;
EXPECT
########

# strict behaviour, without any extra references
use warnings 'untie';
use Tie::Hash ;
tie %h, Tie::StdHash;
untie %h;
EXPECT
########

# strict behaviour, with 1 extra references generating an error
use warnings 'untie';
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
untie %h;
EXPECT
untie attempted while 1 inner references still exist
########

# strict behaviour, with 1 extra references via tied generating an error
use warnings 'untie';
use Tie::Hash ;
tie %h, Tie::StdHash;
$a = tied %h;
untie %h;
EXPECT
untie attempted while 1 inner references still exist
########

# strict behaviour, with 1 extra references which are destroyed
use warnings 'untie';
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
$a = 0 ;
untie %h;
EXPECT
########

# strict behaviour, with extra 1 references via tied which are destroyed
use warnings 'untie';
use Tie::Hash ;
tie %h, Tie::StdHash;
$a = tied %h;
$a = 0 ;
untie %h;
EXPECT
########

# strict error behaviour, with 2 extra references 
use warnings 'untie';
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
$b = tied %h ;
untie %h;
EXPECT
untie attempted while 2 inner references still exist
########

# strict behaviour, check scope of strictness.
no warnings 'untie';
use Tie::Hash ;
$A = tie %H, Tie::StdHash;
$C = $B = tied %H ;
{
    use warnings 'untie';
    use Tie::Hash ;
    tie %h, Tie::StdHash;
    untie %h;
}
untie %H;
EXPECT
########
# Forbidden aggregate self-ties
my ($a, $b) = (0, 0);
sub Self::TIEHASH { bless $_[1], $_[0] }
sub Self::DESTROY { $b = $_[0] + 1; }
{
    my %c = 42;
    tie %c, 'Self', \%c;
}
EXPECT
Self-ties of arrays and hashes are not supported 
########
# Allowed scalar self-ties
my ($a, $b) = (0, 0);
sub Self::TIESCALAR { bless $_[1], $_[0] }
sub Self::DESTROY   { $b = $_[0] + 1; }
{
    my $c = 42;
    $a = $c + 0;
    tie $c, 'Self', \$c;
}
die unless $a == 0 && $b == 43;
EXPECT
########
# Interaction of tie and vec

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
# An attempt at lvalueable barewords broke this

tie FH, 'main';
EXPECT

