#!/usr/bin/perl -Tw

BEGIN {
    if ($ENV{PERL_CORE}) {
	require Config; import Config;
	no warnings 'once';
	if ($Config{extensions} !~ /\bHash\/Util\b/) {
	    print "1..0 # Skip: Hash::Util was not built\n";
	    exit 0;
	}
    }
}

use strict;
use Test::More;

sub numbers_first { # Sort helper: All digit entries sort in front of others
                    # Makes sorting portable across ASCII/EBCDIC
    return $a cmp $b if ($a =~ /^\d+$/) == ($b =~ /^\d+$/);
    return -1 if $a =~ /^\d+$/;
    return 1;
}

my @Exported_Funcs;
BEGIN {
    @Exported_Funcs = qw(
                     bucket_array
                     bucket_info
                     bucket_stats
                     hash_seed
                     hash_value
                     hv_store
                    );
    plan tests => 19 + @Exported_Funcs;
    use_ok 'Hash::Util', @Exported_Funcs;
}
foreach my $func (@Exported_Funcs) {
    can_ok __PACKAGE__, $func;
}

my $hash_seed = hash_seed();
my $hash_seed_hex = unpack("H*", $hash_seed);
ok(defined($hash_seed) && $hash_seed ne '', "hash_seed ($hash_seed_hex)");

{
    my $x='foo';
    my %test;
    hv_store(%test,'x',$x);
    is($test{x},'foo','hv_store() stored');
    $test{x}='bar';
    is($x,'bar','hv_store() aliased');
    is($test{x},'bar','hv_store() aliased and stored');
}

{
    my $h1= hash_value("foo");
    my $h2= hash_value("bar");
    is( $h1, hash_value("foo"), "hash value for 'foo' is repeatable" );
    is( $h2, hash_value("bar"), "hash value for 'bar' is repeatable" );

    my $seed= hash_seed();
    my $h1s= hash_value("foo",$seed);
    my $h2s= hash_value("bar",$seed);

    is( $h1s, hash_value("foo",$seed), "hash value for 'foo' is repeatable with a seed" );
    is( $h2s, hash_value("bar",$seed), "hash value for 'bar' is repeatable with a seed" );

    $seed= join "", map { chr $_ } 1..length($seed);

    my $h1s2= hash_value("foo",$seed);
    my $h2s2= hash_value("bar",$seed);

    is( $h1s2, hash_value("foo",$seed), "hash value for 'foo' is repeatable with a different seed" );
    is( $h2s2, hash_value("bar",$seed), "hash value for 'bar' is repeatable with a different seed" );

    isnt($h1s,$h1s2, "hash value for 'foo' should differ between seeds");
    isnt($h1s,$h1s2, "hash value for 'bar' should differ between seeds");

}

{
    my @info1= bucket_info({});
    my @info2= bucket_info({1..10});
    my @stats1= bucket_stats({});
    my @stats2= bucket_stats({1..10});
    my $array1= bucket_array({});
    my $array2= bucket_array({1..10});
    is("@info1", "0 8 0",
        "Check bucket_info results for empty hash are as expected");
    like("@info2[0,1]", qr/5 (?:8|16)/,
        "check bucket_info results for hash with 5 keys are as expected" );
    is("@stats1", "0 8 0",
        "Check bucket_stats for empty hash are as expected");
    like("@stats2[0,1]", qr/5 (?:8|16)/,
        "Check bucket_stats for hash with 5 keys are as expected");
    my @keys1= sort map { ref $_ ? @$_ : () } @$array1;
    my @keys2= sort map { ref $_ ? @$_ : () } @$array2;
    is("@keys1", "",
        "bucket_array for empty hash should be empty");
    is("@keys2", "1 3 5 7 9",
        "bucket_array for 5 keys should contain all 5 keys");
}
