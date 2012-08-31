#!./perl -w
# Test for malfunctions of utf8 cache

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

plan(tests => 5);

SKIP: {
skip_without_dynamic_extension("Devel::Peek");

my $pid = open CHILD, '-|';
die "kablam: $!\n" unless defined $pid;
unless ($pid) {
    open STDERR, ">&STDOUT";
    $a = "hello \x{1234}";
    for (1..2) {
        bar(substr($a, $_, 1));
    }
    sub bar {
        $_[0] = "\x{4321}";
        Devel::Peek::Dump($_[0]);
    }
    exit;
}

{ local $/; $_ = <CHILD> }

my $utf8magic = qr{ ^ \s+ MAGIC \s = .* \n
                      \s+ MG_VIRTUAL \s = .* \n
                      \s+ MG_TYPE \s = \s PERL_MAGIC_utf8 .* \n
                      \s+ MG_LEN \s = .* \n }xm;

unlike($_, qr{ $utf8magic $utf8magic }x);

} # SKIP

# With bad caching, this code used to go quadratic and take 10s of minutes.
# The 'test' in this case is simply that it doesn't hang.

{
    local ${^UTF8CACHE} = 1; # enable cache, disable debugging
    my $x = "\x{100}" x 1000000;
    while ($x =~ /./g) {
	my $p = pos($x);
    }
    pass("quadratic pos");
}

# Get-magic can reallocate the PV.  Check that the cache is reset in
# such cases.

# Regexp vars
"\x{100}" =~ /(.+)/;
() = substr $1, 0, 1;
"a\x{100}" =~ /(.+)/;
is ord substr($1, 1, 1), 0x100, 'get-magic resets utf8cache on match vars';

# Substr lvalues
my $x = "a\x{100}";
my $l = \substr $x, 0;
() = substr $$l, 1, 1;
substr $x, 0, 1, = "\x{100}";
is ord substr($$l, 1, 1), 0x100, 'get-magic resets utf8cache on LVALUEs';

# defelem magic
my %h;
sub {
  $_[0] = "a\x{100}";
  () = ord substr $_[0], 1, 1;
  $h{k} = "\x{100}"x2;
  is ord substr($_[0], 1, 1), 0x100,
    'get-magic resets uf8cache on defelems';
}->($h{k});
