#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc( '../lib' );
    skip_all_if_miniperl("no dynamic loading on miniperl, no POSIX");
}

use 5.010;
use strict;
use Config ();
use POSIX ();

skip_all('getgrgid() not implemented')
    unless eval { my($foo) = getgrgid(0); 1 };

skip_all("No 'id' or 'groups'") if
    $^O eq 'MSWin32' || $^O eq 'NetWare' || $^O eq 'VMS' || $^O =~ /lynxos/i;

skip_all('need to be root') if $> != 0;

Test();
exit;



sub Test {

    plan 2;

    $) = "123";
    is $), "123", "can change egid to '123'";

    $) = "123 123";
    is $), "123 123", "can change egid to '123 123'";

    return;
}

# ex: set ts=8 sts=4 sw=4 et:
