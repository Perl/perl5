#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}
plan(tests => 1);

{ # perl #116190
  fresh_perl_is('print qq!@F!', '1 2',
		{
		 stdin => "1:2",
		 switches => [ '-n', '-F:' ],
		}, "passing -F implies -a");
}
