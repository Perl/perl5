#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;

plan 12;

my $err;
my $err1 = "Unimplemented at $0 line ";
my $err2 = ".\n";

$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { ... };
is $@, $err, "Execution of ellipsis statement reported 'Unimplemented' code";
$@ = '';

note("RT #122661: Semicolon before ellipsis statement disambiguates to indicate block rather than hash reference");
my @input = (3..5);
my @transformed;
$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { @transformed = map {; ... } @input; };
is $@, $err, "Disambiguation case 1";
$@ = '';

$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { @transformed = map {;...} @input; };
is $@, $err, "Disambiguation case 2";
$@ = '';

$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { @transformed = map {; ...} @input; };
is $@, $err, "Disambiguation case 3";
$@ = '';

$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { @transformed = map {;... } @input; };
is $@, $err, "Disambiguation case 4";
$@ = '';

note("RT #132150: ... is a term, not an operator");
$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { ... + 0 };
is $@, $err, "... + 0 parses";
$@ = '';

$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { ... % 1 };
is $@, $err, "... % 1 parses";
$@ = '';

$err = $err1 . ( __LINE__ + 1 ) . $err2;
eval { ... / 1 };
is $@, $err, "... / 1 parses";
$@ = '';

#
# Regression tests, making sure ... is still parsable as an operator.
#
my @lines = split /\n/ => <<'--';

# Check simple range operator.
my @arr = 'A' ... 'D';

# Range operator with print.
print 'D' ... 'A';

# Without quotes, 'D' could be a file handle.
print  D  ...  A ;

# Another possible interaction with a file handle.
print ${\"D"}  ...  A ;
--

foreach my $line (@lines) {
    next if $line =~ /^\s*#/ || $line !~ /\S/;
    my $mess = qq {Parsing '...' in "$line" as a range operator};
    eval qq {
       {local *STDOUT; no strict "subs"; $line;}
        pass \$mess;
        1;
    } or do {
        my $err = $@;
        $err =~ s/\n//g;
        fail "$mess ($err)";
    }
}
