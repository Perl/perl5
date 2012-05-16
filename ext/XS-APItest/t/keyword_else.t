use strict;

use Test::More tests => 17;

my $seen_else;
my $seen_elsif_expr;
my $seen_elsif;
my $seen_continue;

sub _reset {
    undef $_
	for $seen_else, $seen_elsif_expr, $seen_elsif, $seen_continue
}

eval q{
    use XS::APItest ();
    if (1) { }
    else { $seen_else = 1 }
};

is $seen_else, undef, 'if swallows else with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'else';
    if (1) { }
    else { $seen_else = 1 }
};

is $seen_else, undef, 'if swallows else with keyword plugin';

_reset;
eval q{
    use XS::APItest ();
    if (1) { }
    elsif ($seen_elsif_expr = 1) { $seen_elsif = 1 }
};

is_deeply [$seen_elsif_expr,$seen_elsif], [undef,undef],
    'if swallows elsif with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'elsif';
    if (1) { }
    elsif ($seen_elsif_expr = 1) { $seen_elsif = 1 }
};

is_deeply [$seen_elsif_expr,$seen_elsif], [undef,undef],
	'if swallows elsif with keyword plugin';

_reset;
eval q{
    use XS::APItest ();
    if (1) { }
    elsif ($seen_elsif_expr = 1) { $seen_elsif = 1 }
    else { $seen_else = 1 }
};

is_deeply [$seen_elsif_expr,$seen_elsif,$seen_else], [undef,undef,undef],
    'if swallows else and elsif with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'elsif', 'else';
    if (1) { }
    elsif ($seen_elsif_expr = 1) { $seen_elsif = 1 }
    else { $seen_else = 1 }
};

is_deeply [$seen_elsif_expr,$seen_elsif,$seen_else],
	      [undef,undef,undef],
	'if swallows else and elsif with keyword plugin';

_reset;
eval q{
    use XS::APItest ();
    while(1) { last }
    continue { $seen_continue = 1 }
};

is $seen_continue, undef, 'while swallows continue with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'continue';
    while(1) { last }
    continue { $seen_continue = 1 }
};

{
    local $TODO = 'while does not yet hide continue from keyword plugin';
    is $seen_continue, undef,
	'while swallows continue with keyword plugin';
}

_reset;
eval q{
    use XS::APItest ();
    for(1) { last }
    continue { $seen_continue = 1 }
};

is $seen_continue, undef, 'for swallows continue with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'continue';
    for(1) { last }
    continue { $seen_continue = 1 }
};

{
    local $TODO = 'for does not yet hide continue from keyword plugin';
    is $seen_continue, undef, 'for swallows continue with keyword plugin';
}

_reset;
eval q{
    use XS::APItest ();
    foreach(1) { last }
    continue { $seen_continue = 1 }
};

is $seen_continue, undef,
    'foreach swallows continue with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'continue';
    foreach(1) { last }
    continue { $seen_continue = 1 }
};

{
    local $TODO = 'foreach does not yet hide continue from keyword plugin';
    is $seen_continue, undef,
	'foreach swallows continue with keyword plugin';
}

_reset;
eval q{
    use XS::APItest 'continue';
    for(;;) { last }
    continue { $seen_continue = 1 }
};

is $seen_continue, 1, 'for(;;) does not swallow continue';

_reset;
eval q{
    use XS::APItest 'continue';
    foreach(;;) { last }
    continue { $seen_continue = 1 }
};

is $seen_continue, 1, 'foreach(;;) does not swallow continue';

_reset;
eval q{
    use XS::APItest ();
    { last }
    continue { $seen_continue = 1 }
};

is $seen_continue, undef, 'block swallows continue with no keyword plugin';

_reset;
eval q{
    use XS::APItest 'continue';
    { last }
    continue { $seen_continue = 1 }
};

{
    local $TODO = 'block does not yet hide continue from keyword plugin';
    is $seen_continue, undef,
	'block swallows continue with keyword plugin';
}

_reset;
eval q{
    use XS::APItest 'continue';
    { last }
    continue; # dies unless parsed by the keyword plugin
    $seen_continue = 1;
};

is $seen_continue, 1, 'block does not swallow continue;';
