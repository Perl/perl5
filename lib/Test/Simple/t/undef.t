use strict;
use Test::More tests => 10;

BEGIN { $^W = 1; }

my $warnings = '';
local $SIG{__WARN__} = sub { $warnings = join '', @_ };

is( undef, undef,           'undef is undef');
is( $warnings, '',          '  no warnings' );

isnt( undef, 'foo',         'undef isnt foo');
is( $warnings, '',          '  no warnings' );

like( undef, '/.*/',        'undef is like anything' );
is( $warnings, '',          '  no warnings' );

eq_array( [undef, undef], [undef, 23] );
is( $warnings, '',          'eq_array()  no warnings' );

eq_hash ( { foo => undef, bar => undef },
          { foo => undef, bar => 23 } );
is( $warnings, '',          'eq_hash()   no warnings' );

eq_set  ( [undef, undef, 12], [29, undef, undef] );
is( $warnings, '',          'eq_set()    no warnings' );


eq_hash ( { foo => undef, bar => { baz => undef, moo => 23 } },
          { foo => undef, bar => { baz => undef, moo => 23 } } );
is( $warnings, '',          'eq_hash()   no warnings' );


