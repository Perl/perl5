#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require './charset_tools.pl';
}

use strict;
use warnings;

skip_all_without_unicode_tables();

# Token boundaries mark places where an empty construct preserves meaning.
# Keep escapes, classes, and group openers together. Keep a
# quantifier with its atom or closing parenthesis so an inserted group does
# not become the quantifier's operand.
my $sharp_s = uni_to_native("\x{df}");
my @cases = (
    [ 'literal', [ 'a', 'b', 'c' ], [ 'abc', 'xabcabc' ] ],
    [ 'anchors', [ '\A', 'a', 'b', '\z' ], [ 'ab', 'xab' ] ],
    [ 'flat alternatives', [ 'ab', '|', 'cd', '|', 'ef' ],
      [ 'abcdef', 'xefab' ] ],
    [ 'common prefixes',
      [ '\A', '(?:', 'foo', '|', 'food', '|', 'fool', ')', '\z' ],
      [ 'foo', 'food', 'fool', 'fooz' ] ],
    [ 'empty first alternative', [ '\A', '(?:', '|', 'a', ')', '\z' ],
      [ '', 'a', 'b' ] ],
    [ 'empty last alternative', [ '\A', '(?:', 'a', '|', ')', '\z' ],
      [ '', 'a', 'b' ] ],
    [ 'empty middle alternative', [ '(?:', 'ab', '|', '|', 'cd', ')' ],
      [ 'abcd', 'x' ] ],
    [ 'empty alternatives', [ '\A', '(?:', '|', ')', '\z' ],
      [ '', 'a' ] ],
    [ 'jump trie', [ '(?:', 'ab', '[cd]', '|', 'ef', '\d', ')', 'z' ],
      [ 'abcz', 'abdz', 'ef1z', 'abz' ] ],
    [ 'classes', [ '\A', '[ab]', '\d', '[^x]', '\z' ],
      [ 'a1z', 'b2x' ] ],
    [ 'boundaries', [ '\b', 'ab', '\b' ], [ 'ab ab', 'xab' ] ],
    [ 'global position', [ '\G', '(?:', 'ab', '|', 'c', ')' ],
      [ 'abcab', 'abxc', 'cab' ] ],
    [ 'greedy quantifiers', [ '\A', 'a*', 'b+', 'c?', '\z' ],
      [ 'bbc', 'aabb', 'a' ] ],
    [ 'lazy quantifiers', [ 'a*?', 'b+?', 'c??' ],
      [ 'aabbc', 'bbc', 'x' ] ],
    [ 'bounded quantifiers', [ '\A', 'a{1,3}', 'b{0,2}?', '\z' ],
      [ 'a', 'aaabb', 'aaaa' ] ],
    [ 'possessive quantifiers', [ '\A', 'a++', 'b*+', '\z' ],
      [ 'aaabb', 'ab', 'ba' ] ],
    [ 'captures', [ '(', 'a', ')', '(', 'b', ')', '(c)?' ],
      [ 'ab', 'abcabc' ] ],
    [ 'empty capture', [ '(', ')', 'a', '(', 'b?', ')' ],
      [ 'a', 'ab', 'xaa' ] ],
    [ 'optional capture', [ '\A', '(a)?', 'b', '\z' ],
      [ 'b', 'ab', 'a' ] ],
    [ 'repeated capture', [ '\A', '(', '(a)?', 'b', ')+', '\z' ],
      [ 'abb', 'abab', 'bb' ] ],
    [ 'backreference', [ '\A', '(', 'a', '|', 'b', ')', '\1', '\z' ],
      [ 'aa', 'bb', 'ab' ] ],
    [ 'named backreference',
      [ '\A', '(?<word>', 'ab', '|', 'cd', ')', '\k<word>', '\z' ],
      [ 'abab', 'cdcd', 'abcd' ] ],
    [ 'capture conditional',
      [ '\A', '(a)?', '(?(1)', 'b', '|', 'c', ')', '\z' ],
      [ 'ab', 'c', 'ac' ] ],
    [ 'branch reset', [ '\A', '(?|', '(a)', '|', '(b)', ')', '\1', '\z' ],
      [ 'aa', 'bb', 'ab' ] ],
    [ 'positive lookahead', [ '(?=', 'ab', ')', 'a', 'b' ],
      [ 'ab', 'xab', 'ac' ] ],
    [ 'negative lookahead', [ '(?!', 'ab', ')', 'a', '.' ],
      [ 'ac', 'ab', 'xaz' ] ],
    [ 'positive lookbehind', [ '(?<=', 'ab', ')', 'c' ],
      [ 'abc', 'xbc', 'abcabc' ] ],
    [ 'negative lookbehind', [ '(?<!', 'ab', ')', 'c' ],
      [ 'abc', 'xbc', 'cc' ] ],
    [ 'atomic group', [ '\A', '(?>', 'ab', '|', 'a', ')', 'b', '\z' ],
      [ 'abb', 'ab' ] ],
    [ 'keep', [ 'a', '\K', 'b' ], [ 'ab', 'abab', 'ac' ] ],
    [ 'multiline anchors', [ '(?m)', '^', 'a', '$' ],
      [ "x\na\nb", 'a', 'ab' ] ],
    [ 'folded alternatives', [ '(?i)', '(?:', 'ab', '|', 'cd', ')' ],
      [ 'ABcd', 'aB', 'ef' ] ],
    [ 'folded single letters', [ '(?i)', '\A', '(?:', '|', 'a', ')', '\z' ],
      [ '', 'a', 'A' ] ],
    [ 'non-folding alternatives', [ '(?i)', '(?:', '_', '|', 'ab', ')' ],
      [ '_AB_', 'ab', 'x' ] ],
    [ 'mixed folding', [ '(?:', '(?i:', 'ab', ')', '|', 'cd', ')' ],
      [ 'AB', 'cd', 'CD' ] ],
    [ 'ASCII folding', [ '(?aai)', '(?:', 'ss', '|', '_', ')' ],
      [ 'SS', $sharp_s, '_' ] ],
    [ 'Unicode folding', [ '(?ui)', '(?:', 'ss', '|', '_', ')' ],
      [ 'SS', $sharp_s, '_' ] ],
    [ 'wide alternatives', [ '(?:', '\x{100}', 'b', '|', '\x{10000}', ')' ],
      [ "\x{100}b", "\x{10000}", 'ab' ] ],
    [ 'wide folding', [ '(?ui)', '(?:', '\x{100}', 'b', '|', 'cd', ')' ],
      [ "\x{101}B", 'CD', 'ab' ] ],
    [ 'nested alternatives',
      [ '\A', '(?:', 'a', '(?:', 'b', '|', '(?:', 'c', '|', 'd', ')', ')',
        '|', 'ef', ')', '\z' ],
      [ 'ab', 'ac', 'ad', 'ef', 'ae' ] ],
    [ 'deep empty alternatives',
      [ '\A', '(?:', '|', '(?:', '|', '(?:', '|', 'a', ')', ')', ')', '\z' ],
      [ '', 'a', 'b' ] ],
    [ 'deep captures',
      [ '\A', '(', 'a', '(?:', '(', 'b', '(', 'c?', ')', ')', '|', 'd', ')',
        ')', '\z' ],
      [ 'ab', 'abc', 'ad', 'ac' ] ],
    [ 'nested quantifiers',
      [ '\A', '(?:', 'a', '(?:', 'b', '(?:', 'c', '|', 'd', ')+', ')+', ')+',
        '\z' ],
      [ 'abc', 'abcd', 'abcbdabcd', 'abcabc', 'ab' ] ],
    [ 'nested optional captures',
      [ '\A', '(?:', '(', 'a', '(?:', '(b)?', 'c', ')+', ')?', 'd', ')+',
        '\z' ],
      [ 'd', 'acdd', 'abcd', 'acacdd' ] ],
    [ 'assertions inside alternatives',
      [ '\A', '(?:', '(?=', '(', 'ab', ')', ')', '(?:', 'ab', '|', 'ac', ')',
        '|', '(?!', 'ab', ')', '(', 'a', '.', ')', ')', '\z' ],
      [ 'ab', 'ac', 'ad', 'ba' ] ],
    [ 'nested assertions',
      [ '(?=', '(?:', 'a', '(?=', 'b', '(?!', 'c', ')', ')', ')', ')',
        'a', 'b' ],
      [ 'ab', 'abc', 'xabd' ] ],
    [ 'nested atomic group',
      [ '\A', '(?>', '(?:', 'ab', '|', 'a', ')', '(?:', 'c', '|', 'd', ')',
        ')', 'e', '\z' ],
      [ 'abce', 'ade', 'abde', 'ace', 'abe' ] ],
    [ 'nested folded trie',
      [ '(?ui)', '\A', '(?:', '|', '(?:', 'ab', '|', '(?:', 'cd', '|',
        '\x{100}', 'e', ')', ')', ')', '\z' ],
      [ '', 'AB', 'CD', "\x{101}E", 'abce' ] ],
    [ 'subroutine',
      [ '\A', '(?<word>', 'a', '(?:', 'b', '|', 'c', ')', ')', '(?&word)',
        '\z' ],
      [ 'abac', 'acab', 'abab', 'ab' ] ],
    [ 'recursive group',
      [ '\A', '(?<nest>', 'a', '(?&nest)?', 'b', ')', '\z' ],
      [ 'ab', 'aabb', 'aaabbb', 'aab' ] ],
);

for my $prefix_case ([ 'short', 'a' ], [ 'longer', 'ab' ],
                     [ 'wide', "\x{100}" ]) {
    my ($name, $prefix) = @$prefix_case;
    my @protected = ('(?:', '(?:', $prefix, '(*SKIP)', 'b', '|',
                     $prefix, 'c', ')', '|', $prefix, '(*COMMIT)', 'b', ')');
    my @sibling = ('x', '(*THEN)', 'y');
    my @subjects = ($prefix . $prefix . 'b', $prefix . 'b',
                    $prefix . 'c', 'xy', $prefix, 'z');

    push @cases,
        [ "protected trie with $name prefix first",
          [ @protected, '|', @sibling, '|', $prefix ], [ @subjects ] ],
        [ "protected trie with $name prefix in middle",
          [ @sibling, '|', @protected, '|', $prefix ], [ @subjects ] ];
}

for my $depth (4, 8, 16) {
    my @nested = ('c');
    for (1 .. $depth) {
        @nested = ('(?:', 'a', @nested, '|', 'b', ')');
    }
    push @cases, [ "alternatives nested $depth levels",
                   [ '\A', @nested, '\z' ],
                   [ ('a' x $depth) . 'c', ('a' x ($depth - 1)) . 'b',
                     'b', 'c', ('a' x $depth) . 'd' ] ];
}

my @trie_modes = (
    [ 'compiler default', undef ],
    [ 'zero trie limit', 0 ],
    [ 'trie disabled', -1 ],
);

# These forms succeed without consuming input or changing captures. Comments
# exercise parsing even though they do not emit a matching node. Empty
# captures and negative assertions do not preserve the original pattern.
# Empty atomic groups use SUSPEND, whose interaction with pending
# control-verb failure needs separate coverage.
my @empty_forms = ('(?:)', '(?i:)', '(?=)', '(?<=)', '(?:|)',
                   'a{0}', '(?#)');

sub compile_pattern {
    my ($pattern, $limit) = @_;
    local ${^RE_TRIE_MAXBUF} = $limit;

    # Include the limit in the pattern to prevent reuse of a compiled regex
    # when only the trie setting changes. Construct the comment in a string
    # because regex comments do not interpolate variables.
    my $mode = defined $limit ? $limit : 'default';
    my $source = "(?#trie limit $mode)$pattern";
    return qr/$source/;
}

sub match_spans {
    my ($regex, $subject) = @_;
    my @matches;

    while ($subject =~ /$regex/g) {
        my @starts = @-;
        my @ends = @+;

        # Capture spans identify their text as well as distinguishing an
        # unmatched capture from one that matched the empty string.
        push @matches, join '/',
            join(',', map { defined $_ ? $_ : '-' } @starts),
            join(',', map { defined $_ ? $_ : '-' } @ends);
    }

    return join ';', @matches;
}

for my $case (@cases) {
    my ($name, $tokens, $subjects) = @$case;
    my $original = join '', @$tokens;
    my $control = compile_pattern($original, -1);
    my @variants = ([ 'original', $original ]);

    for my $empty (@empty_forms) {
        for my $boundary (0 .. @$tokens) {
            my @injected = @$tokens;
            splice @injected, $boundary, 0, $empty;
            push @variants, [ "$empty at boundary $boundary",
                              join '', @injected ];
        }
        push @variants,
            [ "$empty at all boundaries",
              $empty . join($empty, @$tokens) . $empty ];
    }

    for my $upgrade (0, 1) {
        my @targets = @$subjects;
        if ($upgrade) {
            utf8::upgrade($_) for @targets;
        }
        my @expected = map { match_spans($control, $_) } @targets;

        for my $mode (@trie_modes) {
            my ($mode_name, $limit) = @$mode;
            for my $variant (@variants) {
                my ($insertion, $pattern) = @$variant;
                my $regex = eval { compile_pattern($pattern, $limit) };
                my $label = "$name, $insertion, $mode_name, upgrade=$upgrade";

                if (!defined $regex) {
                    fail("$label compiles");
                    diag("Pattern: $pattern\n$@");
                    next;
                }

                for my $i (0 .. $#targets) {
                    is(match_spans($regex, $targets[$i]), $expected[$i],
                       "$label, subject $i")
                        or diag("Original: $original\nInjected: $pattern");
                }
            }
        }
    }
}

done_testing();
