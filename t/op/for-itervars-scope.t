#!./perl

# Test lexical scope of `for` statement, variant: `for $var (@array)` (foreach)
# Tested behaviour:
# - capability to declare / use given cursor
# - visibility of given cursor in both for-block and continue-block
# - behaviour of cursor after for-loop (exists? what value?)

BEGIN {
	chdir 't' if -d 't';
	require "./test.pl";
	set_up_inc('../lib');
}

use v5.38;

assume q ([for-itervars] global cursor is visible in `continue` block and its original value is preserved)
	=> expect => q (/Foo.Foo=42)
	=> eval   => q {
		my $cursor_global = 42;

		for $cursor_global (qw (Foo)) {
			$result .= q (/) . $cursor_global;
		} continue {
			$result .= q (.) . $cursor_global;
		}

		$result .= q (=) . ($cursor_global // q ([undef]));
	};

assume q ([for-itervars] `our` cursor is visible in continue block)
	=> expect => q (/Foo.Foo)
	=> eval   => q {
		use warnings FATAL => q (all);

		for our $cursor_our_continue (qw (Foo)) {
			$result .= q (/) . $cursor_our_continue;
		} continue {
			$result .= q (.) . $cursor_our_continue;
		}

		$result;
	};

assume q ([for-itervars] `our` cursor is not visible after `for` loop)
	=> throws => qr (^Variable "\$cursor_our_after" is not imported)
	=> eval   => q {
		use warnings FATAL => q (all);

		for our $cursor_our_after (qw (Foo)) {
		}

		$result .= $cursor_our_after;
	};

assume q ([for-itervars] `our` cursor redeclares already declared global variable)
	=> throws => qr (^"our" variable .cursor_redeclared redeclared)
	=> eval   => q {
		use warnings FATAL => q (all);

		our $cursor_redeclared = 42;

		for our $cursor_redeclared () {
		}
	};

assume q ([for-itervars] `my` cursor is visible in `continue` block)
	=> expect => q (/Foo.Foo)
	=> eval   => q {
		use warnings FATAL => q (all);

		for my $cursor_my (q (Foo)) {
			$result .= q (/) . $cursor_my;
		} continue {
			$result .= q (.) . $cursor_my;
		}

		$result;
	};

assume q ([for-itervars] `my` cursor is not visible after `for` loop)
	=> throws => qr (^Global symbol "\$cursor_my_after" requires explicit package name)
	=> eval   => q {
		use strict;
		use warnings;

		for my $cursor_my_after (q (Foo)) {
		}

		$cursor_my_after;
	};

assume q ([for-itervars] `my` multi-cursors are visible in `continue` block)
	=> expect => q (/FooBar.FooBar)
	=> eval   => q {
		use warnings FATAL => q (all);

		for my ($cursor_multi_1, $cursor_multi_2) (qw (Foo Bar)) {
			$result .= q (/) . $cursor_multi_1 . $cursor_multi_2;
		} continue {
			$result .= q (.) . $cursor_multi_1 . $cursor_multi_2;
		}

		$result;
	};

assume q ([for-itervars] `my` multi-cursors are not visible after `for` loop)
	=> throws => qr (^Global symbol "\$cursor_my_multi_1" requires explicit package name)
	=> eval   => q {
		use warnings FATAL => q (all);

		for my ($cursor_my_multi_1, $cursor_my_multi_2) (qw (Foo Bar)) {
		} continue {
		}

		$cursor_my_multi_1;
	};

assume q ([for-itervars] `refaliasing` global cursor preserves it's original value)
	=> expect => q (/Foo.Foo=42)
	=> eval   => q {
		use warnings FATAL => q (all);
		use experimental qw (refaliasing);

		my $cursor_refalias = 42;

		for \ $cursor_refalias (\ qw (Foo)) {
			$result .= q (/) . $cursor_refalias;
		} continue {
			$result .= q (.) . $cursor_refalias;
		}

		$result . q (=) . $cursor_refalias;
	};

assume q ([for-itervars] `declared_refs` is visible in continue block)
	=> expect => q (/Foo.Foo)
	=> eval   => q {
		use warnings FATAL => q (all);
		use experimental qw (declared_refs);

		for my \ $cursor_refs (\ qw (Foo)) {
			$result .= q (/) . $cursor_refs;
		} continue {
			$result .= q (.) . $cursor_refs;
		}

		$result;
	};

assume q ([for-itervars] `declared_refs` is not visible after loop)
	=> throws => qr (^Global symbol "\$cursor_refs_after" requires explicit package name)
	=> eval   => q {
		use warnings FATAL => q (all);
		use experimental qw (declared_refs);

		for my \ $cursor_refs_after (\ qw (Foo)) {
		}

		$cursor_refs_after;
	};

done_testing;
