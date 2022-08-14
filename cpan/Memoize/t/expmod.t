use Memoize::Expire;
use Test::More tests => 8;

tie my %h => 'Memoize::Expire', HASH => \my %backing;

$h{foo} = 1;
my $num_keys = keys %backing;
my $num_refs = grep ref, values %backing;

is $h{foo}, 1, 'setting and getting a plain scalar value works';
cmp_ok $num_keys, '>', 0, 'HASH option is effective';
is $num_refs, 0, 'backing storage contains only plain scalars';

$h{bar} = my $bar = {};
my $num_keys_step2 = keys %backing;
$num_refs = grep ref, values %backing;

is ref($h{bar}), ref($bar), 'setting and getting a reference value works';
cmp_ok $num_keys, '<', $num_keys_step2, 'HASH option is effective';
is $num_refs, 1, 'backing storage contains only one reference';

my $contents = eval { +{ %h } };

ok defined $contents, 'dumping the tied hash works';
is_deeply $contents, { foo => 1, bar => $bar }, ' ... with the expected contents';
