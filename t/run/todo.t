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

my $is_debugging_build = $Config{config_args} =~ /\bDDEBUGGING\b(*nla:=none)/;

our $TODO;

TODO: {
    local $::TODO = 'GH 1420';

    my $data = <<~"HERE";
        AMAZING BUT TRUE ...

        There is so much sand in Northern Africa that if it were spread out it
        would completely cover the Sahara Desert.
        HERE

    my $fh = do {
        local *FH;
        open(FH, '<', \$data);
        *FH{IO};
    };
    0 while <$fh>;
    my $lc = $.;
    close($fh);

    is($lc, 4, 'Correct line count reported from $. when reading from *FH{IO}; GH 1420');

}

TODO: {
    local $::TODO = 'GH 2027';
    my sub new {
        my ($class, $code) = @_;
        return bless $code => $class;
    }
    my @codes;
    for my $i (1 .. 2) {
        push @codes, new('main', sub {});
    }
    isnt($codes[0], $codes[1], 'The same subroutine reference is not re-used when blessed; GH 2027');
}

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
    my $is_rc_stack = "$Config{cc} $Config{ccflags} $Config{optimize}" =~ /-DPERL_RC_STACK\b/;
    local $::TODO = $is_rc_stack ? undef : "GH 13307";

    my $results = fresh_perl(<<~'EOF', {});
        my $iter;
        my %llll;
        sub bbbb { }
        sub aaaa {
            \@_ if $iter & 1;
            bbbb($_[1]) if $iter & 2;
            delete $llll{p};
            print $_[0] // "undef", "\n";
        }
        for(0..3) {
            $iter = $_;
            %llll = (p => "oooo");
            aaaa($llll{p}, undef);
        }
    EOF
    is($results, "oooo\noooo\noooo\noooo", 'Hashref element reference in @_ disappeared; GH 13307');
}

TODO: {
    local $::TODO = "GH 15654";
    my $results = fresh_perl(<<~'EOF', {});
        %: = *: = *:::::: = *x; *:::: = *::;
        EOF
    is($?, 0, 'perl exited normally; [GH 15654]');

    $results = fresh_perl(<<~'EOF', {});
        %y = *y = *:::::: = *x; *:::: = *::;
        EOF
    is($?, 0, 'perl exited normally; [GH 15654]');
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
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16522';
    fresh_perl(<<~'HERE', { stderr => 'devnull' });
        END { exit 0 } # Consider compilation errors a success
        0/v$0sprintf$0$0
        HERE
    is($?, 0, 'No assertion failure; GH 16522');
}

TODO: {
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16863';
    fresh_perl(<<~'HERE', { stderr => 'devnull' });
        END { exit 0 }
        00.=my$0=00.0
        HERE
    is($?, 0, 'No assertion failure; GH 16863');
}

TODO: {
    local $::TODO = 'GH 16865';
    fresh_perl('\(sort { 0 } 0, 0 .. "a")', { stderr => 'devnull' });
    is($?, 0, "No assertion failure; GH 16865");
}

TODO: {
    todo_skip "Test needs -DDEBUGGING", 1 unless $is_debugging_build;
    local $::TODO = 'GH 16869';
    fresh_perl(<<~'HERE', {});
        my $glob = ("0" x 4094) . "?";
        glob $glob;
        HERE
    is($?, 0, 'No assertion failure; GH 16869');
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
    local $::TODO = 'GH 19378';
    fresh_perl_like(
        <<~'HERE',
            sub () { !0 };
            for (!0) { $_++ };
            HERE
        qr/Modification of a read-only value/,
        {},
        "'sub () { !0 }' does not prevent 'Modification of a read-only value' error; GH 19378"
    );
    isnt($?, 0, 'Compilation fails; GH 19378');
}

TODO: {
    local $::TODO = 'GH 20491';
    use experimental 'defer';
    my $deferred = 0;
    do {
        defer { $deferred = 1 };
    };
    is($deferred, 1, 'defer in single-expression do block runs when exiting block; GH 20491');
}

TODO: {
    local $::TODO = 'GH 21827';
    my $test = 18446744073709550592;
    my @warnings = capture_warnings(sub { localtime $test });
    {
        local $::TODO = 0;
        is(scalar @warnings, 2, 'Correct number of warnings captured; GH 21827');
    }
    for my $w (@warnings) {
        like($w, qr/localtime\($test\)/, 'localtime() warnings reports correct value when given too large of a number; GH 21827');
    }
}

TODO: {
    todo_skip 1 if is_miniperl();
    local $::TODO = 'GH 22168';
    fresh_perl_is(
        <<~'HERE',
            use Scalar::Util qw(tainted);
            my $in = <STDIN>;
            print tainted(chr $in);
            HERE
        '1',
        { stdin => '36', switches => [ '-t' ] },
        'chr() does not lose tainting; GH 22168'
    );
}

TODO: {
    todo_skip 2 if is_miniperl();
    local $::TODO = 'GH 22192';
    fresh_perl_is(
        <<~'HERE',
            use Scalar::Util qw(tainted);
            my $y = <STDIN>;
            vec( my $x = "", 0, 8 ) = $y;
            print tainted($x);
            HERE
        '1',
        { stdin => '123', switches => [ '-t' ] },
        'lvalue vec() propagates tainting on empty string; GH 22192'
    );
    fresh_perl_is(
        <<~'HERE',
            use Scalar::Util qw(tainted);
            my $y = <STDIN>;
            vec( my $x = "X", 0, 8 ) = $y;
            print tainted($x);
            HERE
        '1',
        { stdin => '123', switches => [ '-t' ] },
        'lvalue vec() propagates tainting on non-empty string; GH 22192'
    );
}

done_testing();
