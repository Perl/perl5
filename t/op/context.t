#!./perl

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc( qw(. ../lib) );
}

require "./test.pl";
plan( tests => 8 );

sub foo {
    $a='abcd';
    $a=~/(.)/g;
    cmp_ok($1,'eq','a','context ' . curr_test());
}

my $a=foo;
my @a=foo;
foo;
foo(foo);

my $before = curr_test();
my %h;
$h{foo} = foo;
my $after = curr_test();

cmp_ok($after-$before,'==',1,'foo called once')
	or diag("nr tests: before=$before, after=$after");

my $cx;
sub context {
    $cx = qw[void scalar list][wantarray + defined wantarray];
}
$_ = sub { context(); BEGIN { } }->();
is($cx, 'scalar', 'context of { foo(); BEGIN {} }');
