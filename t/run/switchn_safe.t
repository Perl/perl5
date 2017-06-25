#!./perl -N

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    $file = '|safe_argv.tmp';
    open(TRY, '>', $file) || (die "Can't open temp file: $!");
    print TRY "ok 1\nok 2\n";
    close TRY or die "Could not close: $!";
    @ARGV = ($file);
    plan(tests => 3);
}

END {
    pass("Final test");
}

chomp;
is("ok ".$., $_, "Checking line $.");

s/^/not /;
