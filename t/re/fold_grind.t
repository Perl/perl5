# Grind out a lot of combinatoric tests for folding.  Still missing are
# testing backreferences and tries.

use charnames ":full";

binmode STDOUT, ":utf8";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use warnings;

# Tests both unicode and not, so make sure not implicitly testing unicode
no feature 'unicode_strings';

# Case-insensitive matching is a large and complicated issue.  Perl does not
# implement it fully, properly.  For example, it doesn't include normalization
# as part of the equation.  To test every conceivable combination is clearly
# impossible; these tests are mostly drawn from visual inspection of the code
# and experience, trying to exercise all areas.

# There are three basic ranges of characters that Perl may treat differently:
# 1) Invariants under utf8 which on ASCII-ish machines are ASCII, and are
#    referred to here as ASCII.  On EBCDIC machines, the non-ASCII invariants
#    are all controls that fold to themselves.
my $ASCII = 1;

# 2) Other characters that fit into a byte but are different in utf8 than not;
#    here referred to, taking some liberties, as Latin1.
my $Latin1 = 2;

# 3) Characters that won't fit in a byte; here referred to as Unicode
my $Unicode = 3;

# Within these basic groups are equivalence classes that testing any character
# in is likely to lead to the same results as any other character.  This is
# used to cut down the number of tests needed, unless PERL_RUN_SLOW_TESTS is
# set.
my $skip_apparently_redundant = ! $ENV{PERL_RUN_SLOW_TESTS};

sub range_type {
    my $ord = shift;

    return $ASCII if $ord < 128;
    return $Latin1 if $ord < 256;
    return $Unicode;
}

sub numerically {
    return $a <=> $b
}

my %tests;
my %simple_folds;
my %multi_folds;

# First, analyze the current Unicode's folding rules
my %folded_from;
my $file="../lib/unicore/CaseFolding.txt";
open my $fh, "<", $file or die "Failed to read '$file': $!";
while (<$fh>) {
    chomp;

    # Lines look like (though without the initial '#')
    #0130; F; 0069 0307; # LATIN CAPITAL LETTER I WITH DOT ABOVE

    my ($line, $comment) = split / \s+ \# \s+ /x, $_;
    next if $line eq "" || substr($line, 0, 1) eq '#';
    my ($hex_from, $fold_type, @folded) = split /[\s;]+/, $line;

    my $from = hex $hex_from;

    if ($fold_type eq 'F') {
        next;   # XXX TODO multi-char folds
        my $from_range_type = range_type($from);
        @folded = map { hex $_ } @folded;

        # Include three code points that are handled internally by the regex
        # engine specially, plus all non-Unicode multi folds (which actually
        # the only one is already included in the three, but this makes sure)
        # And if any member of the fold is not the same range type as the
        # source, add it directly to the tests.  It needs to be an array of an
        # array, so that it is distinguished from multiple single folds
        if ($from == 0xDF || $from == 0x390 || $from == 0x3B0
            || $from_range_type != $Unicode
            || grep { range_type($_) != $from_range_type } @folded)
        {
            $tests{$from} = [ [ @folded ] ];
        }
        else {

            # Must be Unicode here, so chr is automatically utf8.  Get the
            # number of bytes in each.  This is because the optimizer cares
            # about length differences.
            my $from_length = length encode('utf-8', chr($from));
            my $to_length = length encode('utf-8', pack 'U*', @folded);
            push @{$multi_folds{$from_length}{$to_length}}, { $from => [ @folded ] };
        }
    }

    # Perl only deals with C and F folds
    next if $fold_type ne 'C';

    # C folds are single-char $from to single-char $folded
    push @{$folded_from{hex $folded[0]}}, $from;
}

# Now try to sort the single char folds into equivalence classes of that are
# likely to have identical successes and failures.  Any fold that crosses
# range types is suspect, and is automatically tested.  Otherwise, store by
# the number of characters that participate in a fold.  Likely all folds in a
# range type that fold to each other like B->b->B will have identical success
# and failure; similarly all folds that have three characters participating
# are likely to have the same successes and failures, etc.
foreach my $folded (sort numerically keys %folded_from) {
    my $target_range_type  = range_type($folded);
    my $count = @{$folded_from{$folded}};

    # Automatically test any fold that crosses range types
    if (grep { range_type($_) != $target_range_type } @{$folded_from{$folded}})
    {
        $tests{$folded} = $folded_from{$folded};
    }
    else {
        push @{$simple_folds{$target_range_type}{$count}},
               { $folded => $folded_from{$folded} };
    } 
}

foreach my $from_length (keys %multi_folds) {
    foreach my $fold_length (keys %{$multi_folds{$from_length}}) {
        #print __LINE__, ref $multi_folds{$from_length}{$fold_length}, Dumper $multi_folds{$from_length}{$fold_length};
        foreach my $test (@{$multi_folds{$from_length}{$fold_length}}) {
            #print __LINE__, ": $from_length, $fold_length, $test:\n";
            my ($target, $pattern) = each %$test;
            #print __LINE__, ": $target: $pattern\n";
            $tests{$target} = $pattern;
            last if $skip_apparently_redundant;
        }
    }
}

# Add in tests for single character folds.  Add tests for each range type,
# and within those tests for each number of characters participating in a
# fold.  Thus B->b has two characters participating.  But K->k and Kelvin
# Sign->k has three characters participating.  So we would make sure that
# there is a test for 3 chars, 4 chars, ... .  (Note that the 'k' example is a
# bad one because it crosses range types, so is automatically tested.  In the
# Unicode range there are various of these 3 and 4 char classes, but aren't as
# easily described as the 'k' one.)
foreach my $type (keys %simple_folds) {
    foreach my $count (keys %{$simple_folds{$type}}) {
        foreach my $test (@{$simple_folds{$type}{$count}}) {
            my ($target, $pattern) = each %$test;
            $tests{$target} = $pattern;
            last if $skip_apparently_redundant;
        }
    }
}

# For each range type, test additionally a character that folds to itself
$tests{0x3A} = [ 0x3A ];
$tests{0xF7} = [ 0xF7 ];
$tests{0x2C7} = [ 0x2C7 ];

my $clump_execs = 10000;    # Speed up by building an 'exec' of many tests
my @eval_tests;

# For use by pairs() in generating combinations
sub prefix {
    my $p = shift;
    map [ $p, $_ ], @_ 
}

# Returns all ordered combinations of pairs of elements from the input array.
# It doesn't return pairs like (a, a), (b, b).  Change the slice to an array
# to do that.  This was just to have fewer tests.
sub pairs (@) { 
    #print __LINE__, ": ", join(" XXX ", @_), "\n";
    map { prefix $_[$_], @_[0..$_-1, $_+1..$#_] } 0..$#_ 
}


# Finally ready to do the tests
my $count=1;
foreach my $test (sort { numerically } keys %tests) {

  my $previous_target;
  my $previous_pattern;
  my @pairs = pairs(sort numerically $test, @{$tests{$test}});

  # Each fold can be viewed as a closure of all the characters that
  # participate in it.  Look at each possible pairing from a closure, with the
  # first member of the pair the target string to match against, and the
  # second member forming the pattern.  Thus each fold member gets tested as
  # the string, and the pattern with every other member in the opposite role.
  while (my $pair = shift @pairs) {
    my ($target, $pattern) = @$pair;

    # When testing a char that doesn't fold, we can get the same
    # permutation twice; so skip all but the first.
    next if $previous_target
            && $previous_target == $target
            && $previous_pattern == $pattern;
    ($previous_target, $previous_pattern) = ($target, $pattern);

    # Each side may be either a single char or a string.  Extract each into an
    # array (perhaps of length 1)
    my @target, my @pattern;
    @target = (ref $target) ? @$target : $target;
    @pattern = (ref $pattern) ? @$pattern : $pattern;

    # Have to convert non-utf8 chars to native char set
    @target = map { $_ > 255 ? $_ : ord latin1_to_native(chr($_)) } @target;
    @pattern = map { $_ > 255 ? $_ : ord latin1_to_native(chr($_)) } @pattern;

    # Get in hex form.
    my @x_target = map { sprintf "\\x{%04X}", $_ } @target;
    my @x_pattern = map { sprintf "\\x{%04X}", $_ } @pattern;

    my $target_above_latin1 = grep { $_ > 255 } @target;
    my $pattern_above_latin1 = grep { $_ > 255 } @pattern;
    my $is_self = @target == 1 && @pattern == 1 && $target[0] == $pattern[0];

    # We don't test multi-char folding into other multi-chars.  We are testing
    # a code point that folds to or from other characters.  Find the single
    # code point for diagnostic purposes.  (If both are single, choose the
    # target string)
    my $ord = @target == 1 ? $target[0] : $pattern[0];
    my $progress = sprintf "\"%s\" and /%s/",
                            join("", @x_target),
                            join("", @x_pattern);
    #print $progress, "\n";
    #diag $progress;

    # Now grind out tests, using various combinations.
    foreach my $uni_semantics ("", 'u') {   # Both non- and uni semantics
      foreach my $utf8_target (0, 1) {    # Both utf8 and not, for
                                          # code points < 256
        my $upgrade_target = "";

        # These must already be in utf8 because the string to match has
        # something above latin1.  So impossible to test if to not to be in
        # utf8; and otherwise, no upgrade is needed.
        next if $target_above_latin1 && ! $utf8_target;
        $upgrade_target = '; utf8::upgrade($c)' if ! $target_above_latin1 && $utf8_target;

        foreach my $utf8_pattern (0, 1) {
          next if $pattern_above_latin1 && ! $utf8_pattern;
          my $upgrade_pattern = "";
          $upgrade_pattern = '; utf8::upgrade($p)' if ! $pattern_above_latin1 && $utf8_pattern;

          my $lhs = join "", @x_target;
          my @rhs = @x_pattern;
          #print "$lhs: ", "/@rhs/\n";

          foreach my $bracketed (1) {   # Put rhs in [...], or not
            foreach my $inverted (0,1) {
                next if $inverted && ! $bracketed;

              # In some cases, add an extra character that doesn't fold, and
              # looks ok in the output.
              my $extra_char = "_";
              foreach my $prepend ("", $extra_char) {
                foreach my $append ("", $extra_char) {
                  # Append a char for after quantifier, as results vary if no
                  # char appended.

                  # Assemble the rhs.  Put each character in a separate
                  # bracketed if using charclasses.  This creates a stress on
                  # the code to span a match across multiple elements
                  my $rhs = "";
                  foreach my $rhs_char (@rhs) {
                      $rhs .= '[' if $bracketed;
                      $rhs .= '^' if $inverted;
                      $rhs .=  $rhs_char;

                      # Add a character to the class, so class doesn't get
                      # optimized out
                      $rhs .= '_]' if $bracketed;
                  }

                  # Add one of: no capturing parens
                  #             a single set
                  #             a nested set
                  # Use quantifiers and extra variable width matches inside
                  # them to keep some optimizations from happening
                  foreach my $parend (0, 1, 2) {
                    my $interior = (! $parend)
                                    ? $rhs
                                    : ($parend == 1)
                                        ? "(${rhs},?)"
                                        : "((${rhs})+,?)";
                    foreach my $quantifier ("", '?', '*', '+', '{1,3}') {

                      # A ? or * quantifier normally causes the thing to be
                      # able to match a null string
                      my $quantifier_can_match_null = $quantifier eq '?' || $quantifier eq '*';

                      # But since we only quantify the last character in a
                      # multiple fold, the other characters will have width,
                      # except if we are quantifying the whole rhs
                      my $can_match_null = $quantifier_can_match_null && (@rhs == 1 || $parend);

                      foreach my $l_anchor ("", '^') { # '\A' didn't change result)
                        foreach my $r_anchor ("", '$') { # '\Z', '\z' didn't change result)

                          # The folded part can match the null string if it
                          # isn't required to have width, and there's not
                          # something on one or both sides that force it to.
                          my $must_match = ! $can_match_null || ($l_anchor && $r_anchor) || ($l_anchor && $append) || ($r_anchor && $prepend) || ($prepend && $append);
                          #next unless $must_match;
                          my $quantified = "(?$uni_semantics:$l_anchor$prepend$interior${quantifier}$append$r_anchor)";
                          my $op;
                          if ($must_match && ! $utf8_target && ! $utf8_pattern && ! $uni_semantics && $ord >= 128 && $ord < 256 && ! $is_self)  {
                              $op = 0;
                          } else {
                              $op = 1;
                          }
                          $op = ! $op if $must_match && $inverted;
                          $op = ($op) ? '=~' : '!~';

                          my $stuff .= " utf8_target=$utf8_target, uni_semantics=$uni_semantics, utf8_pattern=$utf8_pattern, bracketed=$bracketed, prepend=$prepend, append=$append, parend=$parend, quantifier=$quantifier, l_anchor=$l_anchor, r_anchor=$r_anchor";
                          my $eval = "my \$c = \"$prepend$lhs$append\"$upgrade_target; my \$p = qr/$quantified/i$upgrade_pattern; \$c $op \$p";

                          # XXX Doesn't currently test multi-char folds
                          next if @pattern != 1;
                          #next if ! $must_match;
                          push @eval_tests, qq[ok(eval '$eval', '$eval')];
                          $count++;

                          # Group tests
                          if (@eval_tests >= $clump_execs) {
                              eval join ";\n", @eval_tests;
                              undef @eval_tests;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

# Finish up any tests not already done
eval join ";\n", @eval_tests;

plan($count-1);

1
