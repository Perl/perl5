#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

BEGIN {
    plan(5);
}

#1
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Hello; print cm()',
	      'ok',
	      { switches => ['-A=Hello'] }, '-A=Hello');

#2
fresh_perl_is('sub cm : assertion { "ok" }; use assertions SDFJKS; print cm()',
	      'ok',
	      { switches => ['-A=.*'] }, '-A=.*');

#3
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Bye; print cm()',
	      'ok',
	      { switches => ['-A=B.e'] }, '-A=B.e');

#4
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Hello; print cm()',
	      '0',
	      { switches => ['-A=NoH..o'] }, '-A=NoH..o');

#5
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Hello; print cm()',
             'ok',
             { switches => ['-A'] }, '-A');

