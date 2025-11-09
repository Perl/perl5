#!./perl

# Test lexical scope of `for` statement, variant: `for (init; control condition; post iterate)`

BEGIN {
	chdir 't' if -d 't';
	require "./test.pl";
	set_up_inc('../lib');
}

use v5.38;

assume q ([for-cstyle] modifies global variable)
	=> expect => q (3)
	=> eval   => eval_this_code q {
		no strict;
		no warnings;

		for ($control_global = 1; $control_global < 3; ++$control_global) { }

		$control_global // q (undef);
	};

assume q ([for-cstyle] `my` variable is restricted into `for`'s lexical scope)
	=> expect => q (42)
	=> eval   => eval_this_code q {
		use strict;
		use warnings FATAL => q (all);

		my $control_my = 42;

		for (my $control_my = 1; $control_my < 3; ++$control_my) { }

		$control_my;
	};

assume q ([for-cstyle] `our` variable declared inside `for` scope isn't visible outside)
	=> throws => qr (^Variable ".control_our" is not imported)
	=> eval   => eval_this_code q {
		use strict;
		use warnings FATAL => q (all);

		for (our $control_our = 1; $control_our < 3; ++$control_our) { }

		$control_our;
	};

assume q ([for-cstyle] `our` variable inside `for` scope redeclares outer variable)
	=> throws => qr (^"our" variable .control_redeclared redeclared)
	=> eval   => eval_this_code q {
		use strict;
		use warnings FATAL => q (all);

		our $control_redeclared = 42;

		for (our $control_redeclared = 1; $control_redeclared < 3; ++$control_redeclared) { }

		$control_redeclared;
	};

assume q ([for-cstyle] `local` localizes variable )
	=> expect => q (3)
	=> eval   => eval_this_code q {
		use strict;
		use warnings FATAL => q (all);

		our $control_local = 42;

		for (local $control_local = 1; $control_local < 3; ++$control_local) { }

		$control_local;
	};

done_testing;
