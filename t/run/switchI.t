#!./perl -IFoo::Bar -IBla

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
    require './test.pl';	# for which_perl() etc
}

BEGIN {
    plan(4);
}

ok(grep { $_ eq 'Bla' } @INC);
SKIP: {
  skip 'Double colons not allowed in dir spec', 1 if $^O eq 'VMS';
  ok(grep { $_ eq 'Foo::Bar' } @INC);
}

fresh_perl_is('print grep { $_ eq "Bla2" } @INC', 'Bla2',
	      { switches => ['-IBla2'] }, '-I');
SKIP: {
  skip 'Double colons not allowed in dir spec', 1 if $^O eq 'VMS';
  fresh_perl_is('print grep { $_ eq "Foo::Bar2" } @INC', 'Foo::Bar2',
	        { switches => ['-IFoo::Bar2'] }, '-I with colons');
}
