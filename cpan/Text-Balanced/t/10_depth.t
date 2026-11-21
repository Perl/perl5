#!perl
#===============================================================================
#
# t/10_depth.t
#
# DESCRIPTION
#   Test script for the $MAX_DEPTH recursion guard.
#   _match_codeblock and _match_tagged each track recursion depth via
#   $Text::Balanced::_depth (localised on entry) and fail when it exceeds
#   $Text::Balanced::MAX_DEPTH.
#
#   extract_tagged propagates failure (undef) cleanly when the depth limit is
#   hit, so its boundary is exactly MAX_DEPTH + 1 levels.
#
#   extract_codeblock's internal loop can return a truncated match for inputs
#   slightly above MAX_DEPTH (the outer levels succeed; the inner levels that
#   hit the guard are treated as unmatched plain text).  Failure (undef) is
#   guaranteed for inputs sufficiently larger than MAX_DEPTH.  We test both the
#   "succeeds at the limit" and "fails well above the limit" cases.
#
# COPYRIGHT
#   Copyright (C) 2026 Steve Hay.  All rights reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Test::More;
use Text::Balanced qw(extract_codeblock extract_tagged);

#===============================================================================
# SUBROUTINES
#===============================================================================

sub make_nested_code {
    my ($depth) = @_;
    # No spaces between braces so each inner '{' triggers a recursive call.
    return ('{' x $depth) . ('}' x $depth);
}

sub make_nested_tag {
    my ($depth) = @_;
    return ('<A>' x $depth) . 'x' . ('</A>' x $depth);
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

# -------------------------------------------------------------------------
# extract_codeblock
# -------------------------------------------------------------------------

{
    local $Text::Balanced::MAX_DEPTH = 10;

    # Nesting at or below the limit must succeed and return the full match.
    for my $n (1, 5, 10) {
        my $text = make_nested_code($n);
        my ($match) = extract_codeblock($text);
        ok defined($match),          "extract_codeblock: $n levels of nesting succeeds";
        is length($match), $n * 2,   "extract_codeblock: $n levels returns full match";
        is $@, undef,                "extract_codeblock: no error at $n levels";
    }

    # Well above the limit the call must fail (return undef).
    # (Inputs only slightly above MAX_DEPTH may return a truncated match as
    # the guard fires deep in the call stack and outer levels partially
    # succeed; inputs much larger than MAX_DEPTH fail completely.)
    for my $n (100, 500) {
        my $text = make_nested_code($n);
        my ($match) = extract_codeblock($text);
        ok !defined($match), "extract_codeblock: $n levels of nesting fails";
        ok defined($@),      "extract_codeblock: \$@ is set at $n levels";
    }

    # $_depth resets between calls: a failed call must not leave residue that
    # causes a subsequent valid call to fail.
    {
        my $deep = make_nested_code(100);
        extract_codeblock($deep);           # expected to fail

        my $shallow = '{}';
        my ($match) = extract_codeblock($shallow);
        ok defined($match), 'extract_codeblock: $_depth resets after a failed call';
    }
}

# Default MAX_DEPTH is restored after the local block.
is $Text::Balanced::MAX_DEPTH, 10_000,
    'extract_codeblock: MAX_DEPTH restored to default after local override';

# Raising MAX_DEPTH allows previously-failing depths to succeed.
{
    local $Text::Balanced::MAX_DEPTH = 20;

    my $text = make_nested_code(20);
    my ($match) = extract_codeblock($text);
    ok defined($match),          'extract_codeblock: 20 levels succeeds with MAX_DEPTH=20';
    is length($match), 40,       'extract_codeblock: 20 levels returns full match with MAX_DEPTH=20';

    my $big = make_nested_code(500);
    ($match) = extract_codeblock($big);
    ok !defined($match), 'extract_codeblock: 500 levels still fails with MAX_DEPTH=20';
}

# -------------------------------------------------------------------------
# extract_tagged
# -------------------------------------------------------------------------

{
    local $Text::Balanced::MAX_DEPTH = 10;

    # Nesting at or below the limit must succeed.
    for my $n (1, 5, 10) {
        my $text = make_nested_tag($n);
        my ($match) = extract_tagged($text, '<A>', '</A>');
        ok defined($match), "extract_tagged: $n levels of nesting succeeds";
        is $@, undef,       "extract_tagged: no error at $n levels";
    }

    # extract_tagged propagates failure cleanly: the boundary is exactly
    # MAX_DEPTH + 1 (= 11 with MAX_DEPTH=10).
    {
        my $text = make_nested_tag(11);
        my ($match) = extract_tagged($text, '<A>', '</A>');
        ok !defined($match), 'extract_tagged: MAX_DEPTH+1 levels of nesting fails';
        ok defined($@),      'extract_tagged: $@ is set when depth exceeded';
    }

    for my $n (20, 100) {
        my $text = make_nested_tag($n);
        my ($match) = extract_tagged($text, '<A>', '</A>');
        ok !defined($match), "extract_tagged: $n levels of nesting fails";
    }

    # $_depth resets between calls.
    {
        my $deep = make_nested_tag(100);
        extract_tagged($deep, '<A>', '</A>');   # expected to fail

        my $shallow = '<A>x</A>';
        my ($match) = extract_tagged($shallow, '<A>', '</A>');
        ok defined($match), 'extract_tagged: $_depth resets after a failed call';
    }
}

is $Text::Balanced::MAX_DEPTH, 10_000,
    'extract_tagged: MAX_DEPTH restored to default after local override';

# Raising MAX_DEPTH allows previously-failing depths to succeed.
{
    local $Text::Balanced::MAX_DEPTH = 20;

    my $text = make_nested_tag(20);
    my ($match) = extract_tagged($text, '<A>', '</A>');
    ok defined($match), 'extract_tagged: 20 levels succeeds with MAX_DEPTH=20';

    my $text21 = make_nested_tag(21);
    ($match) = extract_tagged($text21, '<A>', '</A>');
    ok !defined($match), 'extract_tagged: 21 levels fails with MAX_DEPTH=20';
}

done_testing;

#===============================================================================
