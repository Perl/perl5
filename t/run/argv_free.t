#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    skip_all_without_config('d_fcntl');
}

system $^X, '-e', 'close STDIN; map <>, @ARGV', 1, 2;
is($?, 0, '@ARGV does not conflict with <>');

done_testing;
