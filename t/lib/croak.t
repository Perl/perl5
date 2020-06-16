#!./perl

chdir 't' if -d 't';
@INC = '../lib';

our $FATAL = 1; # we expect all the tests to croak
require "../t/lib/common.pl";
