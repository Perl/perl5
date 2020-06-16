#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

no warnings 'once';
$main::use_crlf = 1;
-e './io/through.t' or die "no file 'io/through.t'";
do './io/through.t' or die "Errors from 'io/through.t':\n$@";
