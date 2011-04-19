#!./perl
# Tests counting number of FETCHes.
#
# See Bugs #76814 and #87708.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    plan (tests => 210);
}

use strict;
use warnings;

my $count = 0;

# Usage:
#   tie $var, "main", $val;          # FETCH returns $val
#   tie $var, "main", $val1, $val2;  # FETCH returns the values in order,
#                                    # one at a time, repeating the last
#                                    # when the list is exhausted.
sub TIESCALAR {my $pack = shift; bless [@_], $pack;}
sub FETCH {$count ++; @{$_ [0]} == 1 ? ${$_ [0]}[0] : shift @{$_ [0]}}
sub STORE { unshift @{$_[0]}, $_[1] }


sub check_count {
    my $op = shift;
    my $expected = shift() // 1;
    is $count, $expected,
        "FETCH called " . (
          $expected == 1 ? "just once" : 
          $expected == 2 ? "twice"     :
                           "$count times"
        ) . " using '$op'";
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
$dummy  = !$var         ; check_count '!';
tie my $v_1, "main", 0;
$dummy  =  $v_1  ||   1 ; check_count '||';
$dummy  = ($v_1  or   1); check_count 'or';
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
$dummy  =  $var =~ y/ //; check_count 'y///';
           /$var/       ; check_count 'm/pattern/';
           /$var foo/   ; check_count 'm/$tied foo/';
          s/$var//      ; check_count 's/pattern//';
          s/$var foo//  ; check_count 's/$tied foo//';
          s/./$var/     ; check_count 's//replacement/';

# Dereferencing
tie my $var1 => 'main', \1;
$dummy  = $$var1        ; check_count '${}';
tie my $var2 => 'main', [];
$dummy  = @$var2        ; check_count '@{}';
$dummy  = shift $var2   ; check_count 'shift arrayref';
tie my $var3 => 'main', {};
$dummy  = %$var3        ; check_count '%{}';
$dummy  = keys $var3    ; check_count 'keys hashref';
{
    no strict 'refs';
    tie my $var4 => 'main', **;
    $dummy  = *$var4        ; check_count '*{}';
}

tie my $var5 => 'main', sub {1};
$dummy  = &$var5        ; check_count '&{}';


###############################################
#        Tests for  $foo binop $foo           #
###############################################

# These test that binary ops call FETCH twice if the same scalar is used
# for both operands. They also test that both return values from
# FETCH are used.

my %mutators = map { ($_ => 1) } qw(. + - * / % ** << >> & | ^);


sub _bin_test {
    my $int = shift;
    my $op = shift;
    my $exp = pop;
    my @fetches = @_;

    $int = $int ? 'use integer; ' : '';

    tie my $var, "main", @fetches;
    is(eval "$int\$var $op \$var", $exp, "retval of $int\$var $op \$var");
    check_count "$int$op", 2;

    return unless $mutators{$op};

    tie my $var2, "main", @fetches;
    is(eval "$int \$var2 $op= \$var2", $exp, "retval of $int \$var2 $op= \$var2");
    check_count "$int$op=", 3;
}

sub bin_test {
    _bin_test(0, @_);
}

sub bin_int_test {
    _bin_test(1, @_);
}

bin_test '**',  2, 3, 8;
bin_test '*' ,  2, 3, 6;
bin_test '/' , 10, 2, 5;
bin_test '%' , 11, 2, 1;
bin_test 'x' , 11, 2, 1111;
bin_test '-' , 11, 2, 9;
bin_test '<<', 11, 2, 44;
bin_test '>>', 44, 2, 11;
bin_test '<' ,  1, 2, 1;
bin_test '>' , 44, 2, 1;
bin_test '<=', 44, 2, "";
bin_test '>=',  1, 2, "";
bin_test '!=',  1, 2, 1;
bin_test '<=>', 1, 2, -1;
bin_test 'le',  4, 2, "";
bin_test 'lt',  1, 2, 1;
bin_test 'gt',  4, 2, 1;
bin_test 'ge',  1, 2, "";
bin_test 'eq',  1, 2, "";
bin_test 'ne',  1, 2, 1;
bin_test 'cmp', 1, 2, -1;
bin_test '&' ,  1, 2, 0;
bin_test '|' ,  1, 2, 3;
bin_test '^' ,  3, 5, 6;
bin_test '.' ,  1, 2, 12;
bin_test '==',  1, 2, "";
bin_test '+' ,  1, 2, 3;
bin_int_test '*' ,  2, 3, 6;
bin_int_test '/' , 10, 2, 5;
bin_int_test '%' , 11, 2, 1;
bin_int_test '+' ,  1, 2, 3;
bin_int_test '-' , 11, 2, 9;
bin_int_test '<' ,  1, 2, 1;
bin_int_test '>' , 44, 2, 1;
bin_int_test '<=', 44, 2, "";
bin_int_test '>=',  1, 2, "";
bin_int_test '==',  1, 2, "";
bin_int_test '!=',  1, 2, 1;
bin_int_test '<=>', 1, 2, -1;
tie $var, "main", 1, 4;
cmp_ok(atan2($var, $var), '<', .3, 'retval of atan2 $var, $var');
check_count 'atan2',  2;

__DATA__
