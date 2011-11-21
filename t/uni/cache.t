BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib .);
    require "test.pl";
}

plan tests => 1;

# Looks to see if a "do 'unicore/lib/Sc/Hira.pl'" is called more than once, by
# putting a compile sub first on the libary path;
# XXX Kludge: requires exact path, which might change, and has deep knowledge
# of how utf8_heavy.pl works, which might also change.

BEGIN { # Make sure catches compile time references
    $::count = 0;
    unshift @INC, sub {
       $::count++ if $_[1] eq 'unicore/lib/Sc/Hira.pl';
    };
}

my $s = 'foo';

$s =~ m/[\p{Hiragana}]/;
$s =~ m/[\p{Hiragana}]/;
$s =~ m/[\p{Hiragana}]/;
$s =~ m/[\p{Hiragana}]/;

is($::count, 1, "Swatch hash caching kept us from reloading swatch hash.");
