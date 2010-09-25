#!./perl
# Tests counting number of FETCHes.
#
# See Bug #76814.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    plan (tests => 92);
}

use strict;
use warnings;

my $TODO = "Bug 76814";

my $count = 0;

sub TIESCALAR {bless \do {my $var = $_ [1]} => $_ [0];}
sub FETCH {$count ++; ${$_ [0]}}
sub STORE {1;}


sub check_count {
    my $op = shift;
    is $count, 1, "FETCH called just once using '$op'";
    $count = 0;
}

my ($dummy, @dummy);

tie my $var => 'main', 1;

# Assignment.
$dummy  =  $var         ; check_count "=";

# Unary +/-
$dummy  = +$var         ; check_count "unary +";
$dummy  = -$var         ; check_count "unary -";

# Basic arithmetic and string operators.
$dummy  =  $var   +   1 ; check_count '+';
$dummy  =  $var   -   1 ; check_count '-';
$dummy  =  $var   /   1 ; check_count '/';
$dummy  =  $var   *   1 ; check_count '*';
$dummy  =  $var   %   1 ; check_count '%';
$dummy  =  $var  **   1 ; check_count '**';
$dummy  =  $var  <<   1 ; check_count '<<';
$dummy  =  $var  >>   1 ; check_count '>>';
$dummy  =  $var   x   1 ; check_count 'x';
@dummy  = ($var)  x   1 ; check_count 'x';
$dummy  =  $var   .   1 ; check_count '.';
 
# Pre/post in/decrement
           $var ++      ; check_count 'post ++';
           $var --      ; check_count 'post --';
        ++ $var         ; check_count 'pre ++';
        -- $var         ; check_count 'pre --';

# Numeric comparison
$dummy  =  $var  <    1 ; check_count '<';
$dummy  =  $var  <=   1 ; check_count '<=';
$dummy  =  $var  ==   1 ; check_count '==';
$dummy  =  $var  >=   1 ; check_count '>=';
$dummy  =  $var  >    1 ; check_count '>';
$dummy  =  $var  !=   1 ; check_count '!=';
$dummy  =  $var <=>   1 ; check_count '<=>';

# String comparison
$dummy  =  $var  lt   1 ; check_count 'lt';
$dummy  =  $var  le   1 ; check_count 'le';
$dummy  =  $var  eq   1 ; check_count 'eq';
$dummy  =  $var  ge   1 ; check_count 'ge';
$dummy  =  $var  gt   1 ; check_count 'gt';
$dummy  =  $var  ne   1 ; check_count 'ne';
$dummy  =  $var cmp   1 ; check_count 'cmp';

# Bitwise operators
$dummy  =  $var   &   1 ; check_count '&';
$dummy  =  $var   ^   1 ; check_count '^';
$dummy  =  $var   |   1 ; check_count '|';
$dummy  = ~$var         ; check_count '~';

# Logical operators
TODO: {
    local $::TODO = $TODO;
    $dummy  = !$var         ; check_count '!';
    $dummy  =  $var  ||   1 ; check_count '||';
    $dummy  = ($var  or   1); check_count 'or';
}
$dummy  =  $var  &&   1 ; check_count '&&';
$dummy  = ($var and   1); check_count 'and';
$dummy  = ($var xor   1); check_count 'xor';
$dummy  =  $var ? 1 : 1 ; check_count '?:';

# Overloadable functions
$dummy  =   sin $var    ; check_count 'sin';
$dummy  =   cos $var    ; check_count 'cos';
$dummy  =   exp $var    ; check_count 'exp';
$dummy  =   abs $var    ; check_count 'abs';
$dummy  =   log $var    ; check_count 'log';
$dummy  =  sqrt $var    ; check_count 'sqrt';
$dummy  =   int $var    ; check_count 'int';
$dummy  = atan2 $var, 1 ; check_count 'atan2';

# Readline/glob
tie my $var0, "main", \*DATA;
$dummy  = <$var0>       ; check_count '<readline>';
$dummy  = <${var}>      ; check_count '<glob>';

# File operators
$dummy  = -r $var       ; check_count '-r';
$dummy  = -w $var       ; check_count '-w';
$dummy  = -x $var       ; check_count '-x';
$dummy  = -o $var       ; check_count '-o';
$dummy  = -R $var       ; check_count '-R';
$dummy  = -W $var       ; check_count '-W';
$dummy  = -X $var       ; check_count '-X';
$dummy  = -O $var       ; check_count '-O';
$dummy  = -e $var       ; check_count '-e';
$dummy  = -z $var       ; check_count '-z';
$dummy  = -s $var       ; check_count '-s';
$dummy  = -f $var       ; check_count '-f';
$dummy  = -d $var       ; check_count '-d';
$dummy  = -l $var       ; check_count '-l';
$dummy  = -p $var       ; check_count '-p';
$dummy  = -S $var       ; check_count '-S';
$dummy  = -b $var       ; check_count '-b';
$dummy  = -c $var       ; check_count '-c';
$dummy  = -t $var       ; check_count '-t';
$dummy  = -u $var       ; check_count '-u';
$dummy  = -g $var       ; check_count '-g';
$dummy  = -k $var       ; check_count '-k';
$dummy  = -T $var       ; check_count '-T';
$dummy  = -B $var       ; check_count '-B';
$dummy  = -M $var       ; check_count '-M';
$dummy  = -A $var       ; check_count '-A';
$dummy  = -C $var       ; check_count '-C';

# Matching
$_ = "foo";
$dummy  =  $var =~ m/ / ; check_count 'm//';
$dummy  =  $var =~ s/ //; check_count 's///';
$dummy  =  $var ~~    1 ; check_count '~~';
TODO: {
    local $::TODO = $TODO;
    $dummy  =  $var =~ y/ //; check_count 'y///';
               /$var/       ; check_count 'm/pattern/';
              s/$var//      ; check_count 's/pattern//';
}
          s/./$var/     ; check_count 's//replacement/';

# Dereferencing
tie my $var1 => 'main', \1;
$dummy  = $$var1        ; check_count '${}';
tie my $var2 => 'main', [];
$dummy  = @$var2        ; check_count '@{}';
tie my $var3 => 'main', {};
$dummy  = %$var3        ; check_count '%{}';
{
    no strict 'refs';
    tie my $var4 => 'main', **;
    $dummy  = *$var4        ; check_count '*{}';
}

tie my $var5 => 'main', sub {1};
$dummy  = &$var5        ; check_count '&{}';

__DATA__
