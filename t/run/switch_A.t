#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
    require './test.pl';	# for which_perl() etc
}

BEGIN {
    plan(5);
}

#1
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Hello; print cm()',
	      'ok',
	      { switches => ['-AHello'] }, '-A');

#2
fresh_perl_is('sub cm : assertion { "ok" }; use assertions SDFJKS; print cm()',
	      'ok',
	      { switches => ['-A.*'] }, '-A.*');

#3
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Bye; print cm()',
	      'ok',
	      { switches => ['-AB.e'] }, '-AB.e');

#4
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Hello; print cm()',
	      '0',
	      { switches => ['-ANoH..o'] }, '-ANoH..o');

#5
fresh_perl_is('sub cm : assertion { "ok" }; use assertions Hello; print cm()',
             'ok',
             { switches => ['-A'] }, '-A');
