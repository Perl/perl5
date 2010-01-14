#!perl -w
$|=1;
BEGIN {
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bOpcode\b/ && $Config{'osname'} ne 'VMS') {
        print "1..0\n";
        exit 0;
    }
}

use Safe 1.00;
use Test::More tests => 6;

my $safe = Safe->new('PLPerl');
$safe->permit_only(qw(:default sort));

# check basic argument passing and context for anon-subs
my $func = $safe->reval(q{ sub { @_ } });
is_deeply [ $func->() ], [ ];
is_deeply [ $func->("foo") ], [ "foo" ];

my $func = $safe->reval(<<'EOS');

    # uses quotes in { "$a" <=> $b } to avoid the optimizer replacing the block
    # with a hardwired comparison
    { package Pkg; sub p_sort { return sort { "$a" <=> $b } @_; } }
                   sub l_sort { return sort { "$a" <=> $b } @_; }

    return sub { return join(",",l_sort(@_)), join(",",Pkg::p_sort(@_)) }

EOS

is $@, '', 'reval should not fail';
is ref $func, 'CODE', 'reval should return a CODE ref';

my ($l_sorted, $p_sorted) = $func->(@_);
is $l_sorted, "1,2,3";
is $p_sorted, "1,2,3";
