#!./perl

# $RCSfile: do.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:45 $

sub foo1
{
    print $_[0];
    'value';
}

sub foo2
{
    shift;
    print $_[0];
    $x = 'value';
    $x;
}

print "1..20\n";

$_[0] = "not ok 1\n";
$result = do foo1("ok 1\n");
print "#2\t:$result: eq :value:\n";
if ($result eq 'value') { print "ok 2\n"; } else { print "not ok 2\n"; }
if ($_[0] eq "not ok 1\n") { print "ok 3\n"; } else { print "not ok 3\n"; }

$_[0] = "not ok 4\n";
$result = do foo2("not ok 4\n","ok 4\n","not ok 4\n");
print "#5\t:$result: eq :value:\n";
if ($result eq 'value') { print "ok 5\n"; } else { print "not ok 5\n"; }
if ($_[0] eq "not ok 4\n") { print "ok 6\n"; } else { print "not ok 6\n"; }

$result = do{print "ok 7\n"; 'value';};
print "#8\t:$result: eq :value:\n";
if ($result eq 'value') { print "ok 8\n"; } else { print "not ok 8\n"; }

sub blather {
    print @_;
}

do blather("ok 9\n","ok 10\n");
@x = ("ok 11\n", "ok 12\n");
@y = ("ok 14\n", "ok 15\n");
do blather(@x,"ok 13\n",@y);

unshift @INC, '.';

if (open(DO, ">$$.16")) {
    print DO "print qq{ok 16\n} if defined wantarray && not wantarray\n";
    close DO;
}

my $a = do "$$.16";

if (open(DO, ">$$.17")) {
    print DO "print qq{ok 17\n} if defined wantarray &&     wantarray\n";
    close DO;
}

my @a = do "$$.17";

if (open(DO, ">$$.18")) {
    print DO "print qq{ok 18\n} if not defined wantarray\n";
    close DO;
}

do "$$.18";

eval qq{ do qq(a file that does not exist); };
print "not " if $@;
print "ok 19\n";

eval qq{ do uc qq(a file that does not exist); };
print "not " if $@;
print "ok 20\n";

END {
    1 while unlink("$$.16", "$$.17", "$$.18");
}
