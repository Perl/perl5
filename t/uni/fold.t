use strict;
use warnings;

# re/fold_grind.t has more complex tests, but doesn't test every fold

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

binmode *STDOUT, ":utf8";

our $TODO;

plan("no_plan");

# Read in the official case folding definitions.
my $CF = '../lib/unicore/CaseFolding.txt';

die qq[$0: failed to open "$CF": $!\n] if ! open(my $fh, "<", $CF);

my @CF;
my %reverse_fold;
while (<$fh>) {
    # Skip S since we are going for 'F'ull case folding.  I is obsolete starting
    # with Unicode 3.2, but leaving it in does no harm, and allows backward
    # compatibility
    next unless my ($code, $type, $mapping, $name) = $_ =~
            /^([0-9A-F]+); ([CFI]); ((?:[0-9A-F]+)(?: [0-9A-F]+)*); \# (.+)/;

    # Convert any 0-255 range chars to native.
    $code = sprintf("%04X", ord_latin1_to_native(hex $code)) if hex $code < 0x100;
    $mapping = join " ", map { $_ =
                                sprintf("%04X", ord_latin1_to_native(hex $_)) }
                                                            split / /, $mapping;

    push @CF, [$code, $mapping, $type, $name];

    # Get the inverse fold for single-char mappings.
    $reverse_fold{pack "U0U*", hex $mapping} = pack "U0U*", hex $code if $type ne 'F';
}

close($fh) or die "$0 Couldn't close $CF";

foreach my $test_ref (@CF) {
    my ($code, $mapping, $type, $name) = @$test_ref;
    my $c = pack("U0U*", hex $code);
    my $f = pack("U0U*", map { hex } split " ", $mapping);
    my $f_length = length $f;
    foreach my $test (
            qq[":$c:" =~ /:$c:/],
            qq[":$c:" =~ /:$c:/i],
            qq[":$c:" =~ /:[_$c]:/], # Place two chars in [] so doesn't get
                                     # optimized to a non-charclass
            qq[":$c:" =~ /:[_$c]:/i],
            qq[":$c:" =~ /:$f:/i],
            qq[":$f:" =~ /:$c:/i],
    ) {
        ok eval $test, "$code - $name - $mapping - $type - $test";
    }

    # Certain tests weren't convenient to put in the list above since they are
    # TODO's in multi-character folds.
    if ($f_length == 1) {

        # The qq loses the utf8ness of ":$f:".  These tests are not about
        # finding bugs in utf8ness, so make sure it's utf8.
        my $test = qq[my \$s = ":$f:"; utf8::upgrade(\$s); \$s =~ /:[_$c]:/i];
        ok eval $test, "$code - $name - $mapping - $type - $test";
        $test = qq[":$c:" =~ /:[_$f]:/i];
        ok eval $test, "$code - $name - $mapping - $type - $test";
    }
    else {

        # There are two classes of multi-char folds that need more work.  For
        # example,
        #   ":ß:" =~ /:[_s]{2}:/i
        #   ":ss:" =~ /:[_ß]:/i
        #
        # Some of the old tests for the second case happened to pass somewhat
        # coincidentally.  But none would pass if changed to this.
        #   ":SS:" =~ /:[_ß]:/i
        #
        # As the capital SS doesn't get folded.  When those pass, it means
        # that the code has been changed to take into account folding in the
        # string, and all should pass, capitalized or not (this wouldn't be
        # true for [^complemented character classes], for which the fold case
        # is better, but these aren't used in this .t currently.  So, what is
        # done is to essentially upper-case the string for this class (but use
        # the reverse fold not uc(), as that is more correct)
        my $u;
        for my $i (0 .. $f_length - 1) {
            my $cur_char = substr($f, $i, 1);
            $u .= $reverse_fold{$cur_char} || $cur_char;
        }
        my $test;

        # A multi-char fold should not match just one char;
        # e.g., ":ß:" !~ /:[_s]:/i
        $test = qq[":$c:" !~ /:[_$f]:/i];
        ok eval $test, "$code - $name - $mapping - $type - $test";

        TODO: { # e.g., ":ß:" =~ /:[_s]{2}:/i
            local $TODO = 'Multi-char fold in [character class]';

            $test = qq[":$c:" =~ /:[_$f]{$f_length}:/i];
            ok eval $test, "$code - $name - $mapping - $type - $test";
        }

        # e.g., ":SS:" =~ /:[_ß]:/i now pass, so TODO has been removed, but
        # since they use '$u', they are left out of the main loop
        $test = qq[ my \$s = ":$u:"; utf8::upgrade(\$s); \$s =~ /:[_$c]:/i];
        ok eval $test, "$code - $name - $mapping - $type - $test";
    }
}

my $num_tests = curr_test() - 1;

die qq[$0: failed to find casefoldings from "$CF"\n] unless $num_tests > 0;

plan($num_tests);
