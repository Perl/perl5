#!./perl -w

BEGIN {
    unshift @INC, 't';
    unshift @INC, 't/compat' if $] < 5.006002;
    require Config; import Config;
    if ($ENV{PERL_CORE} and $Config{'extensions'} !~ /\bStorable\b/) {
        print "1..0 # Skip: Storable was not built\n";
        exit 0;
    }
    require 'st-dump.pl';
}

use Storable qw(freeze thaw nfreeze thaw);

use Test::More;

# memory usage checked with top
$ENV{PERL_TEST_MEMORY} && $ENV{PERL_TEST_MEMORY} >= 8
    or plan skip_all => "Need 8GB for this test";
$Config{ptrsize} >= 8
    or plan skip_all => "Need 64-bit pointers for this test";

plan tests => 4;

# we might have a lot of RAM, but maybe not so much disk space, so we
# can only test freeze()/thaw().

my $x = "x"; # avoid constant folding the large x op
my $data = [ $x x 0x88000000 ]; # 2GB RAM (and a wee bit)

{
    my $frozen = freeze($data); # another 2GB RAM
    my $thawed = thaw($frozen); # another 2GB RAM
    # and add a bit more in case the following 
    is_deeply($thawed, $data,
              "check in and out match");
    undef $frozen;
    undef $thawed;
}

{
    my $frozen = nfreeze($data);
    my $thawed = thaw($frozen);
    is_deeply($thawed, $data, "check in and out match (netorder)");
    undef $frozen;
    undef $thawed;
}

$x->[0] .= chr(0x100);

{
    my $frozen = freeze($data);
    my $thawed = thaw($frozen);
    is_deeply($thawed, $data,
              "check in and out match (utf8)");
    undef $frozen;
    undef $thawed;
}

{
    my $frozen = nfreeze($data);
    my $thawed = thaw($frozen);
    is_deeply($thawed, $data, "check in and out match (utf8,netorder)");
    undef $frozen;
    undef $thawed;
}

