use Test::More tests => 18;

use_ok('Text::Soundex');
require_ok('Test::More');


ok( 2 eq 2,             'two is two is two is two' );
is(   "foo", "foo",       'foo is foo' );
isnt( "foo", "bar",     'foo isnt bar');
isn't("foo", "bar",     'foo isn\'t bar');

#'#
like("fooble", '/^foo/',    'foo is like fooble');
like("FooBle", '/foo/i',   'foo is like FooBle');

pass('pass() passed');

ok( eq_array([qw(this that whatever)], [qw(this that whatever)]),
    'eq_array with simple arrays' );
ok( eq_hash({ foo => 42, bar => 23 }, {bar => 23, foo => 42}),
    'eq_hash with simple hashes' );
ok( eq_set([qw(this that whatever)], [qw(that whatever this)]),
    'eq_set with simple sets' );

my @complex_array1 = (
                      [qw(this that whatever)],
                      {foo => 23, bar => 42},
                      "moo",
                      "yarrow",
                      [qw(498 10 29)],
                     );
my @complex_array2 = (
                      [qw(this that whatever)],
                      {foo => 23, bar => 42},
                      "moo",
                      "yarrow",
                      [qw(498 10 29)],
                     );

ok( eq_array(\@complex_array1, \@complex_array2),
    'eq_array with complicated arrays' );
ok( eq_set(\@complex_array1, \@complex_array2),
    'eq_set with complicated arrays' );

my @array1 = (qw(this that whatever),
              {foo => 23, bar => 42} );
my @array2 = (qw(this that whatever),
              {foo => 24, bar => 42} );

ok( !eq_array(\@array1, \@array2),
    'eq_array with slightly different complicated arrays' );
ok( !eq_set(\@array1, \@array2),
    'eq_set with slightly different complicated arrays' );

my %hash1 = ( foo => 23,
              bar => [qw(this that whatever)],
              har => { foo => 24, bar => 42 },
            );
my %hash2 = ( foo => 23,
              bar => [qw(this that whatever)],
              har => { foo => 24, bar => 42 },
            );


ok( eq_hash(\%hash1, \%hash2),
    'eq_hash with complicated hashes');

%hash1 = ( foo => 23,
           bar => [qw(this that whatever)],
           har => { foo => 24, bar => 42 },
         );
%hash2 = ( foo => 23,
           bar => [qw(this tha whatever)],
           har => { foo => 24, bar => 42 },
         );

ok( !eq_hash(\%hash1, \%hash2),
    'eq_hash with slightly different complicated hashes' );
