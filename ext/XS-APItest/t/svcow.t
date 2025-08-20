#!perl
use strict;
use warnings;
use XS::APItest;
use B;

use Test::More tests => 11;

{
    # github #21877
    # the regexp engine would COW an SV that had a large
    # SvLEN() in cases where sv_setsv() wouldn't.
    # This led to some surprises.
    # - On cywgin this produced some strange performance problems
    # - In general it meant the (large) buffer of the SV remained
    #   allocated for longer than it otherwise would.
    # Also, since the SV became CoW, further copies would also
    # be CoW, for example, code like:
    #
    # while (<>) { # sv_getsv() currently allocates a large-ish buffer
    #    /regex that (captures)/; # CoW large buffer
    #    push @save, $_; # copy in @save still has that large buffer
    # }
    my $x = "Something\n" x 1000;
    cmp_ok(length $x, '>=', 1250,
           "need to be at least 1250 to be COWed");
    sv_grow($x, 1_000_000);
    my $ref = B::svref_2object(\$x);
    cmp_ok($ref->LEN, '>=', 1_000_000,
           "check we got it longer");
    ok(!SvIsCOW($x), "not cow before");
    is($ref->REFCNT, 1, "expected reference count");
    ok($x =~ /me(.)hing/, "match");
    ok(!SvIsCOW($x), "not cow after");

    # make sure reasonable SVs are COWed
    my $y = "Something\n" x 1000;
    sv_force_normal($y);
    cmp_ok(length $y, '>=', 1250,
           "need to be at least 1250 to be COWed");
    my $ref2 = B::svref_2object(\$y);
    ok(!SvIsCOW($y), "not cow before");
    is($ref2->REFCNT, 1, "expected reference count");
    ok($y =~ /me(.)hing/, "match");
    ok(SvIsCOW($y), "is cow after");
}
