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

%x = ();
$y = 3;
@z = ();
$X::x = 13;

use vars qw($p @q %r *s &t $X::p);

my $tests = 0;

my $e = !(grep /^Name "X::x" used only once: possible typo/, @warns) && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = !(grep /^Name "main::x" used only once: possible typo/, @warns) && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = !(grep /^Name "main::y" used only once: possible typo/, @warns) && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = !(grep /^Name "main::z" used only once: possible typo/, @warns) && 'not ';
print "${e}ok ", ++$tests, "\n";
($e, @warns) = @warns != 4 && 'not ';
print "${e}ok ", ++$tests, "\n";

# this is inside eval() to avoid creation of symbol table entries and
# to avoid "used once" warnings
eval <<'EOE';
$e = ! $main::{p} && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = ! *q{ARRAY} && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = ! *r{HASH} && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = ! $main::{s} && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = ! *t{CODE} && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = defined $X::{q} && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = ! $X::{p} && 'not ';
print "${e}ok ", ++$tests, "\n";
EOE
$e = $@ && 'not ';
print "${e}ok ", ++$tests, "\n";

eval q{use vars qw(@X::y !abc); $e = ! *X::y{ARRAY} && 'not '};
print "${e}ok ", ++$tests, "\n";
$e = $@ !~ /^'!abc' is not a valid variable name/ && 'not ';
print "${e}ok ", ++$tests, "\n";

eval 'use vars qw($x[3])';
$e = $@ !~ /^Can't declare individual elements of hash or array/ && 'not ';
print "${e}ok ", ++$tests, "\n";

{ local $^W;
  eval 'use vars qw($!)';
  ($e, @warns) = ($@ || @warns) ? 'not ' : '';
  print "${e}ok ", ++$tests, "\n";
};

# NB the next test only works because vars.pm has already been loaded
eval 'use warnings "vars"; use vars qw($!)';
$e = ($@ || (shift(@warns)||'') !~ /^No need to declare built-in vars/)
			&& 'not ';
print "${e}ok ", ++$tests, "\n";

no strict 'vars';
eval 'use vars qw(@x%%)';
$e = $@ && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = ! *{'x%%'}{ARRAY} && 'not ';
print "${e}ok ", ++$tests, "\n";
eval '$u = 3; @v = (); %w = ()';
$e = $@ && 'not ';
print "${e}ok ", ++$tests, "\n";

use strict 'vars';
eval 'use vars qw(@y%%)';
$e = $@ !~ /^'\@y%%' is not a valid variable name under strict vars/ && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = *{'y%%'}{ARRAY} && 'not ';
print "${e}ok ", ++$tests, "\n";
eval '$u = 3; @v = (); %w = ()';
my @errs = split /\n/, $@;
$e = @errs != 3 && 'not ';
print "${e}ok ", ++$tests, "\n";
$e = !(grep(/^Global symbol "\$u" requires explicit package name/, @errs))
			&& 'not ';
print "${e}ok ", ++$tests, "\n";
$e = !(grep(/^Global symbol "\@v" requires explicit package name/, @errs))
			&& 'not ';
print "${e}ok ", ++$tests, "\n";
$e = !(grep(/^Global symbol "\%w" requires explicit package name/, @errs))
			&& 'not ';
print "${e}ok ", ++$tests, "\n";

{
    no strict;
    eval 'use strict "refs"; my $zz = "abc"; use vars qw($foo$); my $y = $$zz;';
    $e = $@ ? "" : "not ";
    print "${e}ok ", ++$tests, "# use vars error check modifying other strictness\n";
}
