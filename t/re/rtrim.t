#!./perl

use strict;
use warnings;

# This tests that regexs used for trimming whitespace from end of string
# continue to work consistently when we optimise the regex engine.

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

my $nbs_u = "\xA0\x{100}";
chop $nbs_u;
my $nl_u = "\n\x{100}";
chop $nl_u;
my $empty_u = "\x{100}";
chop $empty_u;

my @tests = (
    ['Hello world'],
    [' Hello world'],
    [' Hello world ', ' Hello world'],
    ['Hello world ', 'Hello world'],

    ["Hello world\n", 'Hello world'],
    [" Hello world\n", ' Hello world'],
    ["Hello world \n", 'Hello world'],
    [" Hello world \n", ' Hello world'],

    ["Yarrrr\r", 'Yarrrr'],
    ["NBS8\xA0", 'NBS8'],
    ["NBSU$nbs_u", 'NBSU'],
    ["\n", ""],
    ["\r\n\t\f ", ""],
    ["!\t", "!"],

    ["EN\x{2002}Space\x{2002}", "EN\x{2002}Space"],
    ["\x{2002}\x{2003}Spaces\x{2004}\x{2005}", "\x{2002}\x{2003}Spaces"],
    ["\x{1680}", ""],
    [$nl_u, ""],
    [$empty_u],
);

plan(80 * @tests);

# Yes this is recursive copy-paste-edit, but I'm not confident that trying to
# generate the code then string eval it is much better. Particularly given the
# corner cases. (+ sometimes doesn't match, * always will, and without //u)
for (@tests) {
    my ($input, $want) = @$_;
    my $pretty = $input;
    my $pretty_want = $want;
    for ($pretty, $pretty_want) {
        next
            unless defined $_;
        s/\n/\\n/g;
        s/\f/\\f/g;
        s/\r/\\r/g;
        s/\t/\\t/g;
        # Normally such complexity would have no place *in* a test for the regex
        # engine, but as this test is testing optimisations it seems acceptable.
        s/([^[:ascii:]])/sprintf "\\x{%X}", ord $1/ge;
    }

    # m// s/// s///r
    # \s or [[:space:]]
    # + or *
    # \z or $
    # // or //u

    if (defined $want) {
        {
            ok($input =~ /\s+\z/u, "qq<$pretty> =~ /\\s+\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s+\z//u, 1, "qq<$pretty> =~ s/\\s+\\z//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//ur, $want, "qq<$pretty> =~ s/\\s+\\z//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s+\\z//ur unchanged");
        }

        {
            ok($input =~ /[[:space:]]+\z/u, "qq<$pretty> =~ /[[:space:]]+\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s+\z//u, 1, "qq<$pretty> =~ s/[[:space:]]+\\z//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//ur, $want, "qq<$pretty> =~ s/[[:space:]]+\\z//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//ur unchanged");
        }

        {
            ok($input =~ /\s*\z/u, "qq<$pretty> =~ /\\s*\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s*\z//u, 1, "qq<$pretty> =~ s/\\s*\\z//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//ur, $want, "qq<$pretty> =~ s/\\s*\\z//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s*\\z//ur unchanged");
        }

        {
            ok($input =~ /[[:space:]]*\z/u, "qq<$pretty> =~ /[[:space:]]*\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s*\z//u, 1, "qq<$pretty> =~ s/[[:space:]]*\\z//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//ur, $want, "qq<$pretty> =~ s/[[:space:]]*\\z//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//ur unchanged");
        }

        {
            ok($input =~ /\s+$/u, "qq<$pretty> =~ /\\s+\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s+$//u, 1, "qq<$pretty> =~ s/\\s+\$//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//ur, $want, "qq<$pretty> =~ s/\\s+\$//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s+\$//ur unchanged");
        }

        {
            ok($input =~ /[[:space:]]+$/u, "qq<$pretty> =~ /[[:space:]]+\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s+$//u, 1, "qq<$pretty> =~ s/[[:space:]]+\$//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//ur, $want, "qq<$pretty> =~ s/[[:space:]]+\$//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\$//ur unchanged");
        }

        {
            ok($input =~ /\s*$/u, "qq<$pretty> =~ /\\s*\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s*$//u, 1, "qq<$pretty> =~ s/\\s*\$//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//ur, $want, "qq<$pretty> =~ s/\\s*\$//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s*\$//ur unchanged");
        }

        {
            ok($input =~ /[[:space:]]*$/u, "qq<$pretty> =~ /[[:space:]]*\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s*$//u, 1, "qq<$pretty> =~ s/[[:space:]]*\$//u");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//ur, $want, "qq<$pretty> =~ s/[[:space:]]*\$//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\$//ur unchanged");
        }
    }
    else {
        {
            ok($input !~ /\s+\z/u, "qq<$pretty> !~ /\\s+\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s+\z//u, "", "qq<$pretty> =~ s/\\s+\\z//u");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//ur, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//ur");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            ok($input !~ /[[:space:]]+\z/u, "qq<$pretty> !~ /[[:space:]]+\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]+\z//u, "", "qq<$pretty> =~ s/[[:space:]]+\\z//u retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//u unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//ur, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//ur unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /\s*\z/u, "qq<$pretty> =~ /\\s*\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s*\z//u, 1, "qq<$pretty> =~ s/\\s*\\z//u");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//ur, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//ur");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /[[:space:]]*\z/u, "qq<$pretty> =~ /[[:space:]]*\\z/u");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]*\z//u, 1, "qq<$pretty> =~ s/[[:space:]]*\\z//u retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//u unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//ur, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//ur unchanged");
        }

        {
            ok($input !~ /\s+$/u, "qq<$pretty> !~ /\\s+\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s+$//u, "", "qq<$pretty> =~ s/\\s+\$//u");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//ur, $input, "qq<$pretty> =~ s/[[:space:]]+\$//ur");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            ok($input !~ /[[:space:]]+$/u, "qq<$pretty> !~ /[[:space:]]+\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]+$//u, "", "qq<$pretty> =~ s/[[:space:]]+\$//u retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]+\$//u unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//ur, $input, "qq<$pretty> =~ s/[[:space:]]+\$//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\$//ur unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /\s*$/u, "qq<$pretty> =~ /\\s*\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/\s*$//u, 1, "qq<$pretty> =~ s/\\s*\$//u");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//ur, $input, "qq<$pretty> =~ s/[[:space:]]*\$//ur");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /[[:space:]]*$/u, "qq<$pretty> =~ /[[:space:]]*\$/u");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]*$//u, 1, "qq<$pretty> =~ s/[[:space:]]*\$//u retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]*\$//u unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//ur, $input, "qq<$pretty> =~ s/[[:space:]]*\$//ur retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\$//ur unchanged");
        }
    }

    # And without //u
    undef $want
        if $input =~ /^NBS8/;

    if (defined $want) {
        {
            ok($input =~ /\s+\z/, "qq<$pretty> =~ /\\s+\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/\s+\z//, 1, "qq<$pretty> =~ s/\\s+\\z//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//r, $want, "qq<$pretty> =~ s/\\s+\\z//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s+\\z//r unchanged");
        }

        {
            ok($input =~ /[[:space:]]+\z/, "qq<$pretty> =~ /[[:space:]]+\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/\s+\z//, 1, "qq<$pretty> =~ s/[[:space:]]+\\z//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//r, $want, "qq<$pretty> =~ s/[[:space:]]+\\z//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//r unchanged");
        }

        {
            ok($input =~ /\s*\z/, "qq<$pretty> =~ /\\s*\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/\s*\z//, 1, "qq<$pretty> =~ s/\\s*\\z//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//r, $want, "qq<$pretty> =~ s/\\s*\\z//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s*\\z//r unchanged");
        }

        {
            ok($input =~ /[[:space:]]*\z/, "qq<$pretty> =~ /[[:space:]]*\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/\s*\z//, 1, "qq<$pretty> =~ s/[[:space:]]*\\z//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//r, $want, "qq<$pretty> =~ s/[[:space:]]*\\z//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//r unchanged");
        }

        {
            ok($input =~ /\s+$/, "qq<$pretty> =~ /\\s+\$/");
            my $copy1 = $input;
            is($copy1 =~ s/\s+$//, 1, "qq<$pretty> =~ s/\\s+\$//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//r, $want, "qq<$pretty> =~ s/\\s+\$//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s+\$//r unchanged");
        }

        {
            ok($input =~ /[[:space:]]+$/, "qq<$pretty> =~ /[[:space:]]+\$/");
            my $copy1 = $input;
            is($copy1 =~ s/\s+$//, 1, "qq<$pretty> =~ s/[[:space:]]+\$//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//r, $want, "qq<$pretty> =~ s/[[:space:]]+\$//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\$//r unchanged");
        }

        {
            ok($input =~ /\s*$/, "qq<$pretty> =~ /\\s*\$/");
            my $copy1 = $input;
            is($copy1 =~ s/\s*$//, 1, "qq<$pretty> =~ s/\\s*\$//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//r, $want, "qq<$pretty> =~ s/\\s*\$//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/\\s*\$//r unchanged");
        }

        {
            ok($input =~ /[[:space:]]*$/, "qq<$pretty> =~ /[[:space:]]*\$/");
            my $copy1 = $input;
            is($copy1 =~ s/\s*$//, 1, "qq<$pretty> =~ s/[[:space:]]*\$//");
            is($copy1, $want, "qq<$pretty> => qq<$pretty_want>");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//r, $want, "qq<$pretty> =~ s/[[:space:]]*\$//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\$//r unchanged");
        }
    }
    else {
        {
            ok($input !~ /\s+\z/, "qq<$pretty> !~ /\\s+\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/\s+\z//, "", "qq<$pretty> =~ s/\\s+\\z//");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//r, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//r");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            ok($input !~ /[[:space:]]+\z/, "qq<$pretty> !~ /[[:space:]]+\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]+\z//, "", "qq<$pretty> =~ s/[[:space:]]+\\z// retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]+\\z// unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+\z//r, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\\z//r unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /\s*\z/, "qq<$pretty> =~ /\\s*\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/\s*\z//, 1, "qq<$pretty> =~ s/\\s*\\z//");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//r, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//r");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /[[:space:]]*\z/, "qq<$pretty> =~ /[[:space:]]*\\z/");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]*\z//, 1, "qq<$pretty> =~ s/[[:space:]]*\\z// retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]*\\z// unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*\z//r, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\\z//r unchanged");
        }

        {
            ok($input !~ /\s+$/, "qq<$pretty> !~ /\\s+\$/");
            my $copy1 = $input;
            is($copy1 =~ s/\s+$//, "", "qq<$pretty> =~ s/\\s+\$//");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//r, $input, "qq<$pretty> =~ s/[[:space:]]+\$//r");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            ok($input !~ /[[:space:]]+$/, "qq<$pretty> !~ /[[:space:]]+\$/");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]+$//, "", "qq<$pretty> =~ s/[[:space:]]+\$// retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]+\$// unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s+$//r, $input, "qq<$pretty> =~ s/[[:space:]]+\$//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]+\$//r unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /\s*$/, "qq<$pretty> =~ /\\s*\$/");
            my $copy1 = $input;
            is($copy1 =~ s/\s*$//, 1, "qq<$pretty> =~ s/\\s*\$//");
            is($copy1, $input, "qq<$pretty> unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//r, $input, "qq<$pretty> =~ s/[[:space:]]*\$//r");
            is($copy2, $input, "qq<$pretty> unchanged");
        }

        {
            # Unlike +, * matches, but doesn't change anything
            ok($input =~ /[[:space:]]*$/, "qq<$pretty> =~ /[[:space:]]*\$/");
            my $copy1 = $input;
            is($copy1 =~ s/[[:space:]]*$//, 1, "qq<$pretty> =~ s/[[:space:]]*\$// retval");
            is($copy1, $input, "qq<$pretty> =~ s/[[:space:]]*\$// unchanged");
            my $copy2 = $input;
            is($copy2 =~ s/\s*$//r, $input, "qq<$pretty> =~ s/[[:space:]]*\$//r retval");
            is($copy2, $input, "qq<$pretty> =~ s/[[:space:]]*\$//r unchanged");
        }
    }
}
