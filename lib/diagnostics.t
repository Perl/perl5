#!./perl -w

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use Test::More tests => 11;

BEGIN {
    my $w;
    $SIG{__WARN__} = sub { $w = shift };
    use_ok('diagnostics');
    is $w, undef, 'no warnings when loading diagnostics.pm';
}

require base;

eval {
    'base'->import(qw(I::do::not::exist));
};

like( $@, qr/^Base class package "I::do::not::exist" is empty/);

# Test for %.0f patterns in perldiag, added in 5.11.0
close STDERR;
open STDERR, ">", \my $warning
    or die "Couldn't redirect STDERR to var: $!";
warn('gmtime(nan) too large');
like $warning, qr/\(W overflow\) You called/, '%0.f patterns';

# L<foo/bar> links
seek STDERR, 0,0;
$warning = '';
warn("accept() on closed socket spanner");
like $warning, qr/"accept" in perlfunc/, 'L<foo/bar> links';

# L<foo|bar/baz> links
seek STDERR, 0,0;
$warning = '';
warn
 'Lexing code attempted to stuff non-Latin-1 character into Latin-1 input';
like $warning, qr/using lex_stuff_pvn or similar/, 'L<foo|bar/baz>';

# Multiple messages with the same description
seek STDERR, 0,0;
$warning = '';
warn 'Code point 0xBEE5 is not Unicode, may not be portable';
like $warning, qr/W utf8/,
   'Message sharing its description with the following message';

# Periods at end of entries in perldiag.pod get matched correctly
seek STDERR, 0,0;
$warning = '';
warn "Execution of -e aborted due to compilation errors.\n";
like $warning, qr/The final summary message/, 'Periods at end of line';

# Test for %d/%u
seek STDERR, 0,0;
$warning = '';
warn "Bad arg length for us, is 4, should be 42";
like $warning, qr/In C parlance/, '%u works';

# Test for %X
seek STDERR, 0,0;
$warning = '';
warn "Unicode surrogate U+C0FFEE is illegal in UTF-8";
like $warning, qr/You had a UTF-16 surrogate/, '%X';

# Strip S<>
seek STDERR, 0,0;
$warning = '';
warn "syntax error";
like $warning, qr/cybernetic version of 20 questions/s, 'strip S<>';
