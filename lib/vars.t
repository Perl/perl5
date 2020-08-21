#!./perl 

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    $ENV{PERL5LIB} = '../lib';
}

$| = 1;

print "1..28\n";

# catch "used once" warnings
my @warns;
BEGIN { $SIG{__WARN__} = sub { push @warns, @_ }; $^W = 1 };

use vars qw($p @q %r *s &t $X::p);

my $tests = 0;
my ($e, $w, $description) = ('') x 3;
my $s = ' - ';

# The 4 variables which follow are declared (as globals) here but never used
# thereafter.  When the program is run with warnings on -- as it is due to $^W
# = 1 above -- each declaration generates a compile-time warning, which is
# what we're testing in tests 1 thru 4 below.  Tests 1 thru 4 FAIL if a
# warning is *not* generated.

%x = ();
$y = 3;
@z = ();
$X::x = 13;

$w = 'Name "X::x" used only once: possible typo';
$e = !(grep /^$w/, @warns) && 'not ';
$description = $s . "Got: $w";
print "${e}ok ", ++$tests, "$description\n";

$w = 'Name "main::x" used only once: possible typo';
$description = $s . "Got: $w";
$e = !(grep /^$w/, @warns) && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$w = 'Name "main::y" used only once: possible typo';
$description = $s . "Got: $w";
$e = !(grep /^$w/, @warns) && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$w = 'Name "main::z" used only once: possible typo';
$description = $s . "Got: $w";
$e = !(grep /^$w/, @warns) && 'not ';
print "${e}ok ", ++$tests, "$description\n";

($e, @warns) = @warns != 4 && 'not ';
print "${e}ok ", ++$tests, $s, scalar(@warns), " warnings so far\n";

# this is inside eval() to avoid creation of symbol table entries and
# to avoid "used once" warnings
eval <<'EOE';
$description = $s . '! $main::{p}';
$e = ! $main::{p} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '! *q{ARRAY}';
$e = ! *q{ARRAY} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '! *r{HASH}';
$e = ! *r{HASH} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '! $main::{s}';
$e = ! $main::{s} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '! *t{CODE}';
$e = ! *t{CODE} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . 'defined $X::{q}';
$e = defined $X::{q} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '! $X::{p}';
$e = ! $X::{p} && 'not ';
print "${e}ok ", ++$tests, "$description\n";
EOE

$description = $s . 'No eval errors at this point';
$e = $@ && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '! *X::y{ARRAY}';
eval q{use vars qw(@X::y !abc); $e = ! *X::y{ARRAY} && 'not '};
print "${e}ok ", ++$tests, "$description\n";

$w = q|'!abc' is not a valid variable name|;
$description = $s . $w;
$e = $@ !~ /^$w/ && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$w = q|Can't declare individual elements of hash or array|;
$description = $s . $w;
eval 'use vars qw($x[3])';
$e = $@ !~ /^$w/ && 'not ';
print "${e}ok ", ++$tests, "$description\n";

{ local $^W;
  $description = $s . 'localized $^W';
  eval 'use vars qw($!)';
  ($e, @warns) = ($@ || @warns) ? 'not ' : '';
  print "${e}ok ", ++$tests, "$description\n";
};

# NB the next test only works because vars.pm has already been loaded
$w = q|No need to declare built-in vars|;
$description = $s . $w;
eval 'use warnings "vars"; use vars qw($!)';
$e = ($@ || (shift(@warns)||'') !~ /^$w/)
			&& 'not ';
print "${e}ok ", ++$tests, "$description\n";

no strict 'vars';
$description = $s . 'qw(@x%%)';
eval 'use vars qw(@x%%)';
$e = $@ && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . q|! *{'x%%'}{ARRAY}|;
$e = ! *{'x%%'}{ARRAY} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '$u, @v, %w';
eval '$u = 3; @v = (); %w = ()';
$e = $@ && 'not ';
print "${e}ok ", ++$tests, "$description\n";

use strict 'vars';
$w = q|'\@y%%' is not a valid variable name under strict vars|;
$description = $s . $w;
eval 'use vars qw(@y%%)';
$e = $@ !~ /^$w/ && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . q|*{'y%%'}{ARRAY}|;
$e = *{'y%%'}{ARRAY} && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . '$u, @v, %w';
eval '$u = 3; @v = (); %w = ()';
my @errs = split /\n/, $@;
$e = @errs != 3 && 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . 'Global symbol $u';
$e = !(grep(/^Global symbol "\$u" requires explicit package name/, @errs))
			&& 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . 'Global symbol @v';
$e = !(grep(/^Global symbol "\@v" requires explicit package name/, @errs))
			&& 'not ';
print "${e}ok ", ++$tests, "$description\n";

$description = $s . 'Global symbol %w';
$e = !(grep(/^Global symbol "\%w" requires explicit package name/, @errs))
			&& 'not ';
print "${e}ok ", ++$tests, "$description\n";

{
    no strict;
    $description = $s . 'use vars error check modifying other strictness';
    eval 'use strict "refs"; my $zz = "abc"; use vars qw($foo$); my $y = $$zz;';
    $e = $@ ? "" : "not ";
    print "${e}ok ", ++$tests, "$description\n";
}
