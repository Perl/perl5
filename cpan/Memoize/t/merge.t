use strict; use warnings;
use Memoize qw(memoize unmemoize);
use Test::More tests => 18;

my (%cache, $num_cache_misses);
sub cacheit {
    ++$num_cache_misses;
    "cacheit result";
}

memoize 'cacheit', LIST_CACHE => [HASH => \%cache], SCALAR_CACHE => 'MERGE';
my $been_here;
{
	is scalar(cacheit()), 'cacheit result', 'scalar context';
	is $num_cache_misses, 1, 'function called once';

	is +(cacheit())[0], 'cacheit result', 'list context';
	is $num_cache_misses, 1, 'function not called again';

	is_deeply [values %cache], [['cacheit result']], 'expected cached value';

	%cache = ();

	is +(cacheit())[0], 'cacheit result', 'list context';
	is $num_cache_misses, 2, 'function again called after clearing the cache';

	is scalar(cacheit()), 'cacheit result', 'scalar context';
	is $num_cache_misses, 2, 'function not called again';

	last if $been_here++;

	unmemoize 'cacheit';
	( $num_cache_misses, %cache ) = ();

	memoize 'cacheit', SCALAR_CACHE => [HASH => \%cache], LIST_CACHE => 'MERGE';
	redo;
}
