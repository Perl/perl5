#!./perl

# This test harness will (eventually) test the "tie" functionality
# without the need for a *DBM* implementation.

# Currently it only tests use strict "untie".

chdir 't' if -d 't';
@INC = "../lib";
$ENV{PERL5LIB} = "../lib";

$|=1;

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
    if ( $status or $results !~ /^$expected/){
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
use strict 'untie';
use Tie::Hash ;
tie %h, Tie::StdHash;
untie %h;
EXPECT
########

# strict behaviour, with 1 extra references generating an error
use strict 'untie';
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
untie %h;
EXPECT
Can't untie: 1 inner references still exist at
########

# strict behaviour, with 1 extra references via tied generating an error
use strict 'untie';
use Tie::Hash ;
tie %h, Tie::StdHash;
$a = tied %h;
untie %h;
EXPECT
Can't untie: 1 inner references still exist at
########

# strict behaviour, with 1 extra references which are destroyed
use strict 'untie';
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
$a = 0 ;
untie %h;
EXPECT
########

# strict behaviour, with extra 1 references via tied which are destroyed
use strict 'untie';
use Tie::Hash ;
tie %h, Tie::StdHash;
$a = tied %h;
$a = 0 ;
untie %h;
EXPECT
########

# strict error behaviour, with 2 extra references 
use strict 'untie';
use Tie::Hash ;
$a = tie %h, Tie::StdHash;
$b = tied %h ;
untie %h;
EXPECT
Can't untie: 2 inner references still exist at
########

# strict behaviour, check scope of strictness.
no strict 'untie';
use Tie::Hash ;
$A = tie %H, Tie::StdHash;
$C = $B = tied %H ;
{
    use strict 'untie';
    use Tie::Hash ;
    tie %h, Tie::StdHash;
    untie %h;
}
untie %H;
EXPECT
