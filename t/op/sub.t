#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan( tests => 8 );

sub empty_sub {}

is(empty_sub,undef,"Is empty");
is(empty_sub(1,2,3),undef,"Is still empty");
@test = empty_sub();
is(scalar(@test), 0, 'Didnt return anything');
@test = empty_sub(1,2,3);
is(scalar(@test), 0, 'Didnt return anything');

# RT #63790:  calling PL_sv_yes as a sub is special-cased to silently
# return (so Foo->import() silently fails if import() doesn't exist),
# But make sure it correctly pops the stack and mark stack before returning.

{
    my @a;
    push @a, 4, 5, main->import(6,7);
    ok(eq_array(\@a, [4,5]), "import with args");

    @a = ();
    push @a, 14, 15, main->import;
    ok(eq_array(\@a, [14,15]), "import without args");

    my $x = 1;

    @a = ();
    push @a, 24, 25, &{$x == $x}(26,27);
    ok(eq_array(\@a, [24,25]), "yes with args");

    @a = ();
    push @a, 34, 35, &{$x == $x};
    ok(eq_array(\@a, [34,35]), "yes without args");
}
