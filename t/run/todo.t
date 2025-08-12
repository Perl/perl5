#!./perl

# This file is a place for tests that are failing at the time they are added
# into this file.  It exists so that anyone can contribute a test without
# having to know about Perl's testing internal structures.
#
# These introductory comments include hints that may be revised from time to
# time as we gain experience with what sorts of things people find confusing.
# Therefore it is a good idea to check what's changed since the last time you
# looked.
#
# To add a test, create a new
#    TODO: {
#       local $::TODO = "GH #####";
#       ...
#    }
#
# block, like the ones already here.  We want to keep the blocks sorted by
# GitHub issue number so that it is easier to check if there already is a test
# for the one you are intending to add.
#
# This file uses the test functionality from t/test.pl.  For the most part,
# these look like the ones that Test::More offers, 'is', 'like', and so forth,
# along with a few extras to handle the case where the failure crashes the
# perl interpreter.  The ones whose names start with 'fresh' require a
# significant amount of sophistication to use correctly.  It's best to start
# out, if possible, by avoiding issues that crash the interpreter and need
# these.

# Some domains have infrastructure which may make it easier to add a test
# there, than to have to set up things here.  These include:
#
#     Domain              Test File
#   deparsing           lib/B/Deparse.t
#   regex matching      t/re/re_tests
#
# Before you add a test here, check that the ticket isn't one of these,
# because we already have todo tests for them (in some other file).
#
# Git Hub issue numbers
#     2207
#     2208
#     2286
#     2931
#     4125
#     4261
#     4370
#     5959
#     8267
#     8945
#     8952
#     9010
#     9406
#    10750
#    14052
#    14630
#    19370
#    19661
#    22547
#
# We keep a list of all the people who have contributed to the Perl 5 project.
# If this is your first time contributing, you will need to add your name to
# this list.  After you have changed this file with your new test and
# committed the result, run
#
#   perl Porting/updateAUTHORS.pl
#
# This will automatically add you (if you weren't there already) to our list
# of contributors.  If so, you will need to commit this change by doing
# something like:
#
#   commit -a -m'[your name here] is now a Perl 5 author'
#
# Adding tests here helps in two ways.  It might show that the bug has already
# been fixed and we just don't know it; or skimming the existing tests here
# might show that there is an existing ticket already open, and the new ticket
# can be marked as duplicate.

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';    # for fresh_perl_is() etc
    set_up_inc('../lib', '.', '../ext/re');
    require './charset_tools.pl';
    require './loc_tools.pl';
}

use Config;
use strict;
use warnings;

my $switches = "";

my $is_debugging_build = $Config{cppflags} =~ /-DDEBUGGING/;


{   # Fixed by acababb42be12ff2986b73c1bfa963b70bb5d54e
    "abab" =~ /(?:[^b]*(?=(b)|(a))ab)*/;
    is($1, undef, "GH #16894");
}

our $TODO;

TODO: {
    local $::TODO = 'GH 5835';
    my $prev_w = $^W;
    $^W = 1;
    {
        local $^W = $^W;
        is($^W, '1', 'local $^W assignment to self ok');
    }
    is($^W, 1, '$^W value prior to localization is restored');
    $^W = $prev_w;
}

TODO: {
    local $::TODO = "GH 16008";
    my $results = fresh_perl(<<~'EOF', {} );
        open my $h, ">", \my $x;
        print $h "hello earthlings\n";
        $h->truncate(6) or die $!;
        print $x;
        EOF
    is($?, 0, 'perl exited normally');

    is $results, 'hello ', "truncate returned the expected output";
    unlike $results, qr/Bad file descriptor/, "truncate did not warn about bad file descriptors";
}

TODO: {
    local $TODO = "GH 16250";
    fresh_perl_is(<<~'EOF',
        "abcde5678" =~ / b (*pla:.*(*plb:(*plb:(.{4}))? (.{5})).$)/x;
        print $1 // "undef", ":", $2 // "undef", "\n";
        "abcde5678" =~ / b .* (*plb:(*plb:(.{4}))? (.{5}) ) .$ /x;
        print $1 // "undef", ":", $2 // "undef", "\n";
        EOF
    "undef:de567\nundef:de567", { eval $switches }, "");
}

TODO: {
    local $::TODO = 'GH 16865';
    fresh_perl('\(sort { 0 } 0, 0 .. "a")', { stderr => 'devnull' });
    is($?, 0, "No assertion failure");
}

TODO: {
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16876';
    fresh_perl('$_ = "a"; s{ x | (?{ s{}{x} }) }{}gx;',
               { stderr => 'devnull' });
    is($?, 0, "No assertion failure");
}

TODO: {
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16952';
    fresh_perl('s/d|(?{})!//.$&>0for$0,l..a0,0..0',
               { stderr => 'devnull' });
    is($?, 0, "No assertion failure");
}

TODO: {
    local $::TODO = 'GH 16971';
    fresh_perl('split(/00|0\G/, "000")',
               { stderr => 'devnull' });
    is($?, 0, "No panic");
}

TODO: {
    local $::TODO = 'GH 18669';

    my $results = fresh_perl(<<~'EOF', {});
        my $x = { arr => undef };
        push(@{ $x->{ decide } ? $x->{ not_here } : $x->{ new } }, "mana");
        print $x->{ new }[0];
        EOF
    is($?, 0, "No assertion failure");
    is($results, 'mana', 'push on non-existent hash entry from ternary autovivifies array ref');

    $results = fresh_perl(<<~'EOF', {});
        my $x = { arr => undef };
        push(@{ $x->{ decide } ? $x->{ not_here } : $x->{ arr } }, "mana");
        print $x->{ arr }[0];
        EOF
    is($?, 0, "No assertion failure");
    is($results, 'mana', 'push on undef hash entry from ternary autovivifies array ref');

}

{
    fresh_perl('use re "eval";
                my @r;
                for$0(qw(0 0)){push@r,qr/@r(?{})/};',
               { stderr => 'devnull' });
    is($?, 0, "No assertion failure");
}

done_testing();
