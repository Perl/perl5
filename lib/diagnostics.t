#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use Test::More tests => 6;

BEGIN { use_ok('diagnostics') }

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
warn 'Code point 0x%X is not Unicode, may not be portable';
like $warning, qr/W utf8/,
   'Message sharing its description with the following message';

