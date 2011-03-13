#!./perl -w

#
# Verify which OP= operators warn if their targets are undefined.
# Based on redef.t, contributed by Graham Barr <Graham.Barr@tiuk.ti.com>
#	-- Robin Barker 
#
# Now almost completely rewritten.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

my (%should_warn, %should_not);
++$should_warn{$_} foreach qw(* / x & ** << >>);
++$should_not{$_} foreach qw(+ - . | ^ && ||);

my %todo_as_tie = reverse (add => '+', subtract => '-',
			   bit_or => '|', bit_xor => '^');

my %integer = reverse (i_add => '+', i_subtract => '-');
$integer{$_} = 0 foreach qw(* / %);

sub TIESCALAR { my $x; bless \$x }
sub FETCH { ${$_[0]} }
sub STORE { ${$_[0]} = $_[1] }

sub test_op {
    my ($tie, $int, $op_seq, $warn, $todo) = @_;
    my $code = "sub {\n";
    $code .= "use integer;" if $int;
    $code .= "my \$x;\n";
    $code .= "tie \$x, 'main';\n" if $tie;
    $code .= "$op_seq;\n}\n";

    my $sub = eval $code;
    is($@, '', "Can eval code for $op_seq");
    local $::TODO;
    $::TODO = "[perl #17809] pp_$todo" if $todo;
    if ($warn) {
	warning_like($sub, qr/^Use of uninitialized value/,
		     "$op_seq$tie$int warns");
    } else {
	warning_is($sub, undef, "$op_seq$tie$int does not warn");
    }
}

# go through all tests once normally and once with tied $x
for my $tie ("", ", tied") {
    foreach my $integer ('', ', int') {
	test_op($tie, $integer, $_, 0) foreach qw($x++ $x-- ++$x --$x);
    }

    foreach (keys %should_warn, keys %should_not) {
	test_op($tie, '', "\$x $_= 1", $should_warn{$_}, $tie && $todo_as_tie{$_});
	next unless exists $integer{$_};
	test_op($tie, ', int', "\$x $_= 1", $should_warn{$_}, $tie && $integer{$_});
    }

    foreach (qw(| ^ &)) {
	test_op($tie, '', "\$x $_= 'x'", $should_warn{$_}, $tie && $todo_as_tie{$_});
    }
}

done_testing();
