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
#
# Each test name should include the GH number.  While still todo, the software
# displays the number, but after they're fixed, we will move them to a
# permanent position in an appropriate test file, and the ticket number would
# get lost.  You could do something like the following:
#    TODO: {
#       local $::TODO = "GH #####";
#       is($got1, $expected1, "your text1 here: GH ####");
#       is($got2, $expected2, 'your text2 here: GH ####');
#       ...
#    }
#
# or something else to get the number in the testname.
#
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

our $TODO;

TODO: {
    local $::TODO = 'GH 5835';
    my $prev_w = $^W;
    $^W = 1;
    {
        local $^W = $^W;
        is($^W, '1', 'local $^W assignment to self ok');
    }
    is($^W, 1, '$^W value prior to localization is restored; GH 5835');
    $^W = $prev_w;

}

TODO: {
    local $TODO = "[GH 8267]";

    "A" =~ /(((?:A))?)+/;
    my $first = $2;

    "A" =~ /(((A))?)+/;
    my $second = $2;

    is($first, $second, "[GH 8267]");
}

TODO: {
    local $TODO = "[GH 8859]";
    fresh_perl_is(<<~'EOF',
        my $mul = 2**32; my $a = 104712103; my $b = 50;
        my $c = 449735057880383538; # For these values, $mul * $a + $b == $c. Thus $diff should be zero.
        my $diff = $c - ($a * $mul + $b);
        printf "%.0f %.0f %.0f %.0f", $a, $b, $c, $diff;
        #printf "\$c $c %0.f\n", $c;
    EOF
    "104712103 50 449735057880383538 0", { eval $switches }, "[GH 8859]");
}

TODO: {
    local $TODO = "[GH 10194]";
    todo_skip 1 if is_miniperl();

    fresh_perl_is(<<~'EOF',
        use Encode;
        use Devel::Peek;

        my $line = "\xe2\x90\x0a";
        chomp(my $str = "\xe2\x90\x0a");

        Encode::_utf8_on($line);
        Encode::_utf8_on($str);

        for ($line, $str) {
            Dump($_);
            # Doesn't crash
            $_ =~ /(.*)/;
            # List context
            () = $_ =~ /(.*)/;
        }
    EOF
    "", { eval $switches }, "[GH 10194]");
}

TODO: {
    local $::TODO = "GH 16008";
    my $results = fresh_perl(<<~'EOF', {} );
        open my $h, ">", \my $x;
        print $h "hello earthlings\n";
        $h->truncate(6) or die $!;
        print $x;
        EOF
    is($?, 0, 'perl exited normally; [GH 16008]');

    is $results, 'hello ', "truncate returned the expected output; [GH 16008]";
    unlike $results, qr/Bad file descriptor/,
           "truncate did not warn about bad file descriptors [GH 16008]";
}

TODO: {
    local $TODO = "GH 16250";
    fresh_perl_is(<<~'EOF',
        "abcde5678" =~ / b (*pla:.*(*plb:(*plb:(.{4}))? (.{5})).$)/x;
        print $1 // "undef", ":", $2 // "undef", "\n";
        "abcde5678" =~ / b .* (*plb:(*plb:(.{4}))? (.{5}) ) .$ /x;
        print $1 // "undef", ":", $2 // "undef", "\n";
        EOF
    "undef:de567\nundef:de567", { eval $switches }, "GH 16250");
}

TODO: {
    local $::TODO = 'GH 16364';

    my @arr;
    my sub foo {
        unshift @arr, 7;
        $_[0] = 3;
    }

    @arr = ();
    $arr[1] = 1;
    foo($arr[5]);
    is($arr[6], 3,
       'Array element outside array range created at correct index from subroutine @_ alias; GH 16364');

    @arr = ();
    $arr[1] = 1;
    foreach (@arr) {
        unshift @arr, 7;
        $_ = 3;
        last;
    }
    is($arr[1], 3, 'Array element created at correct index from foreach $_ alias; GH 16364');

}

TODO: {
    local $::TODO = 'GH 16865';
    fresh_perl('\(sort { 0 } 0, 0 .. "a")', { stderr => 'devnull' });
    is($?, 0, "No assertion failure; GH 16865");
}

TODO: {
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16876';
    fresh_perl('$_ = "a"; s{ x | (?{ s{}{x} }) }{}gx;',
               { stderr => 'devnull' });
    is($?, 0, "No assertion failure; GH 16876");
}

TODO: {
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16952';
    fresh_perl('s/d|(?{})!//.$&>0for$0,l..a0,0..0',
               { stderr => 'devnull' });
    is($?, 0, "No assertion failure; GH 16952");
}

TODO: {
    local $::TODO = 'GH 16971';
    fresh_perl('split(/00|0\G/, "000")',
               { stderr => 'devnull' });
    is($?, 0, "No panic; GH 16971");
}

TODO: {
    local $::TODO = 'GH 18669';

    my $results = fresh_perl(<<~'EOF', {});
        my $x = { arr => undef };
        push(@{ $x->{ decide } ? $x->{ not_here } : $x->{ new } }, "mana");
        print $x->{ new }[0];
        EOF
    is($?, 0, "No assertion failure; GH 18669");
    is($results, 'mana', 'push on non-existent hash entry from ternary autovivifies array ref; GH 18669');

    $results = fresh_perl(<<~'EOF', {});
        my $x = { arr => undef };
        push(@{ $x->{ decide } ? $x->{ not_here } : $x->{ arr } }, "mana");
        print $x->{ arr }[0];
        EOF
    is($?, 0, "No assertion failure; GH 18669");
    is($results, 'mana', 'push on undef hash entry from ternary autovivifies array ref; GH 18669');

}

done_testing();
