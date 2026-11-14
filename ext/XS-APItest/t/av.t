#!perl

use v5.36;

use Test::More tests => 37;
use XS::APItest;

# code stolen from t/op/hash.t
sub guard::DESTROY {
    ${ $_[0] }->();
}
sub guard :prototype(&) {
    my $callback = shift;
    return bless \$callback, "guard";
}

# to insert
{
    my @arr;

    @arr = ('a' .. 'd');
    av_splice_simple @arr, 0, 0, '<';
    is_deeply \@arr, ['<', 'a', 'b', 'c', 'd'];

    @arr = ('a' .. 'd');
    av_splice_simple @arr, 2, 0, '|';
    is_deeply \@arr, ['a', 'b', '|', 'c', 'd'];

    @arr = ('a' .. 'd');
    av_splice_simple @arr, 4, 0, '>';
    is_deeply \@arr, ['a', 'b', 'c', 'd', '>'];

    # insert multiple

    @arr = ('e' .. 'h');
    av_splice_simple @arr, 0, 0, 'a' .. 'd';
    is_deeply \@arr, ['a'..'h'];

    @arr = ('a', 'b',  'g', 'h');
    av_splice_simple @arr, 2, 0, 'c' .. 'f';
    is_deeply \@arr, ['a'..'h'];

    @arr = ('a' .. 'd');
    av_splice_simple @arr, 4, 0, 'e' .. 'h';
    is_deeply \@arr, ['a'..'h'];

    # insert into prealloc area
    @arr = (undef, 'b' .. 'e');
    shift @arr;
    av_splice_simple @arr, 0, 0, 'a';
    is_deeply \@arr, ['a' .. 'e'];

    # insert into mix of prealloc and Move()d area
    shift @arr;
    av_splice_simple @arr, 0, 0, 'Y', 'Z', 'a';
    is_deeply \@arr, ['Y', 'Z', 'a' .. 'e'];

    # we can't really unit-test if this used the prealloc area but at least we
    # hope not to crash or upset valgrind
}

# insert idx from end
{
    my @arr;

    @arr = ('a' .. 'd');
    av_splice_simple @arr, -2, 0, '|';
    is_deeply \@arr, ['a', 'b', '|', 'c', 'd'];

    @arr = ('a' .. 'd');
    av_splice_simple @arr, -4, 0, '<';
    is_deeply \@arr, ['<', 'a', 'b', 'c', 'd'];
}

# to replace
{
    my @arr;

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 0, 1, 'A';
    is_deeply \@arr, ['A', 'b', 'c', 'd', 'e'];

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 2, 1, 'C';
    is_deeply \@arr, ['a', 'b', 'C', 'd', 'e'];

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 4, 1, 'E';
    is_deeply \@arr, ['a', 'b', 'c', 'd', 'E'];
}

# to delete
{
    my @arr;

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 0, 1;
    is_deeply \@arr, [     'b', 'c', 'd', 'e'];

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 2, 1;
    is_deeply \@arr, ['a', 'b',      'd', 'e'];

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 4, 1;
    is_deeply \@arr, ['a', 'b', 'c', 'd'     ];

    # delete multiple

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 0, 3;
    is_deeply \@arr, [               'd', 'e'];

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 1, 3;
    is_deeply \@arr, ['a',                'e'];

    @arr = ('a' .. 'e');
    av_splice_simple @arr, 2, 3;
    is_deeply \@arr, ['a', 'b',              ];
}

# delete invokes destructor immediately
{
    my $destroyed;

    my @arr = ( guard { $destroyed++ } );

    ok !$destroyed, 'Not destroyed before av_splice as delete';
    av_splice_simple @arr, 0, 1;
    ok $destroyed, 'Destroyed after av_splice as delete';

    undef $destroyed;
    (sub {
        ok !$destroyed, 'Not destroyed before av_splice as delete on @_';
        av_splice_simple @_, 0, 1;
    })->( guard { $destroyed++ } );
    ok $destroyed, 'Destroyed after av_splice as delete on @_';
}

# to extract
{
    my @arr;

    @arr = ('a' .. 'e');
    is_deeply [av_splice_simple @arr, 0, 1], ['a'];

    @arr = ('a' .. 'e');
    is_deeply [av_splice_simple @arr, 2, 1], ['c'];

    @arr = ('a' .. 'e');
    is_deeply [av_splice_simple @arr, 4, 1], ['e'];
}

# extract invokes destructor later
{
    my $destroyed;

    my @arr = ( guard { $destroyed++ } );

    ok !$destroyed, 'Not destroyed before av_splice as extract';
    my @ret = av_splice_simple @arr, 0, 1;
    ok !$destroyed, 'Not destroyed after av_splice as extract';
    @ret = ();
    ok $destroyed, 'Destroyed after result array cleared';
}

# delete count bounding
{
    my @arr = ('a' .. 'e');
    is_deeply [av_splice_simple @arr, 2, 15], ['c', 'd', 'e'];
    is_deeply \@arr, ['a', 'b'];

    # nothing left
    is_deeply [av_splice_simple @arr, 2, 1], [];
    is_deeply \@arr, ['a', 'b'];
}

{
    my @arr = 1 .. 3;

    ok !eval { av_splice_simple @arr, 5, 1; } and
        like $@, qr/^Modification of non-creatable array value attempted, subscript 5 /;

    ok !eval { av_splice_simple @arr, -12, 1; } and
        like $@, qr/^Modification of non-creatable array value attempted, subscript -9 /;
}
