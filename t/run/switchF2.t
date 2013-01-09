#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}
plan(tests => 1);

my $cmd = "echo 1 | ./perl -n -F: -e print+\\\@F";
my $got = `$cmd` || '';
my $ok = 0 == $?;
chomp $got;
ok( ($ok and $got eq 1),
  "passing -F implies -a" );
