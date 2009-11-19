#!./perl

BEGIN {
    require "test.pl";
}

plan(2);

fresh_perl_is('$_ = qq{OK\n}; print;', "OK\n",
              'print without arguments outputs $_');
fresh_perl_is('$_ = qq{OK\n}; print STDOUT;', "OK\n",
              'print with only a filehandle outputs $_');
