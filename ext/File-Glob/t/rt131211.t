use strict;
use warnings;
use v5.16.0;
use File::Temp 'tempdir';
use File::Spec::Functions;
use Test::More;
use Time::HiRes qw(time);

plan tests => 13;

my $path = tempdir uc cleanup => 1;
my @files= (
    "x".("a" x 50)."b", # 0
    "abbbbbbbbbbbbc",   # 1
    "abbbbbbbbbbbbd",   # 2
    "aaabaaaabaaaabc",  # 3
    "pq",               # 4
    "r",                # 5
    "rttiiiiiii",       # 6
    "wewewewewewe",     # 7
    "weeeweeeweee",     # 8
    "weewweewweew",     # 9
    "wewewewewewewewewewewewewewewewewq", # 10
    "wtttttttetttttttwr", # 11
);


foreach (@files) {
    open(my $f, ">", catfile $path, $_);
}

my $elapsed_fail= 0;
my $elapsed_match= 0;
my @got_files;
my @no_files;
my $count = 0;

while (++$count < 10) {
    $elapsed_match -= time;
    @got_files= glob catfile $path, "x".("a*" x $count) . "b";
    $elapsed_match += time;

    $elapsed_fail -= time;
    @no_files= glob catfile $path, "x".("a*" x $count) . "c";
    $elapsed_fail += time;
    last if $elapsed_fail > $elapsed_match * 100;
}

is $count,10,
    "tried all the patterns without bailing out";

cmp_ok $elapsed_fail/$elapsed_match,"<",2,
    "time to fail less than twice the time to match";
is "@got_files", catfile($path, $files[0]),
    "only got the expected file for xa*..b";
is "@no_files", "", "shouldnt have files for xa*..c";


@got_files= glob catfile $path, "a*b*b*b*bc";
is "@got_files", catfile($path, $files[1]),
    "only got the expected file for a*b*b*b*bc";

@got_files= sort glob catfile $path, "a*b*b*bc";
is "@got_files", catfile($path, $files[3])." ".catfile($path,$files[1]),
    "got the expected two files for a*b*b*bc";

@got_files= sort glob catfile $path, "p*";
is "@got_files", catfile($path, $files[4]),
    "p* matches pq";

@got_files= sort glob catfile $path, "r*???????";
is "@got_files", catfile($path, $files[6]),
    "r*??????? works as expected";

@got_files= sort glob catfile $path, "w*e*w??e";
is "@got_files", join(" ", sort map { catfile($path, $files[$_]) } (7,8)),
    "w*e*w??e works as expected";

@got_files= sort glob catfile $path, "w*e*we??";
is "@got_files", join(" ", sort map { catfile($path, $files[$_]) } (7,8,9,10)),
    "w*e*we?? works as expected";

@got_files= sort glob catfile $path, "w**e**w";
is "@got_files", join(" ", sort map { catfile($path, $files[$_]) } (9)),
    "w**e**w works as expected";

@got_files= sort glob catfile $path, "*wee*";
is "@got_files", join(" ", sort map { catfile($path, $files[$_]) } (8,9)),
    "*wee* works as expected";

@got_files= sort glob catfile $path, "we*";
is "@got_files", join(" ", sort map { catfile($path, $files[$_]) } (7,8,9,10)),
    "we* works as expected";

