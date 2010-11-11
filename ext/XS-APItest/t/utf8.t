#!perl -w

use strict;
use Test::More;

use XS::APItest;

foreach ([0, '', '', 'empty'],
	 [0, 'N', 'N', '1 char'],
	 [1, 'NN', 'N', '1 char substring'],
	 [-2, 'Perl', 'Rules', 'different'],
	 [0, chr 163, chr 163, 'pound sign'],
	 [1, chr (163) . 10, chr (163) . 1, '10 pounds is more than 1 pound'],
	 [1, chr(163) . chr(163), chr 163, '2 pound signs are more than 1'],
	 [-2, ' $!', " \x{1F42B}!", 'Camels are worth more than 1 dollar'],
	 [-1, '!', "!\x{1F42A}", 'Initial substrings match'],
	) {
    my ($expect, $left, $right, $desc) = @$_;
    my $copy = $right;
    utf8::encode($copy);
    is(bytes_cmp_utf8($left, $copy), $expect, $desc);
    next if $right =~ tr/\0-\377//c;
    utf8::encode($left);
    is(bytes_cmp_utf8($right, $left), -$expect, "$desc reversed");
}

done_testing;
