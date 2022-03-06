#!./perl
#
# Tests for Perl run-time environment variable settings
#
# $PERL5OPT, $PERL5LIB, etc.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    require Config;
    Config->import;
}

skip_all_without_config('d_fork');
skip_all("NO_PERL_HASH_ENV or NO_PERL_HASH_SEED_DEBUG set")
    if $Config{ccflags} =~ /-DNO_PERL_HASH_ENV\b/
    || $Config{ccflags} =~ /-DNO_PERL_HASH_SEED_DEBUG\b/;

my @modes = (
        'NO',
        'RANDOM',
        'DETERMINISTIC'
    ); # 0, 1 and 2 respectively
my $repeat = 50;
plan tests => @modes * 7 * $repeat;
use strict;
our $TODO;

sub my_runperl_and_capture {
    my ($opts_hash, $cmd_array)= @_;
    my ( $out, $err )
        = runperl_and_capture( $opts_hash, $cmd_array );
    my $err_got_data = "";
    while ($err=~s/^(Got.*\n)//) {
        $err_got_data .= $1;
    }
    my @rand_bits_data;
    while ($err=~s/^(PL_hash_rand_bits=.*)\n//m) {
        push @rand_bits_data, $1;
    }
    return ($out, $err, $err_got_data, \@rand_bits_data);
}

# Test that PERL_PERTURB_KEYS works as expected.  We check that we get the same
# results if we use PERL_PERTURB_KEYS = 0 or 2 and we reuse the seed from previous run.
my $print_keys = [
    '-Dh', '-I../lib',
    (is_miniperl() ? () : '-MHash::Util=hash_traversal_mask,num_buckets'),
    '-e',
    'my %h; @h{"A".."Z", "a".."z"}=(); @k=keys %h;'.
      ' print join ":", 0+@k, ' .
      (is_miniperl() ? '' : 'num_buckets(%h),hash_traversal_mask(%h),') .
      ' join "", @k;'
];
for my $mode (@modes) {
    my $base_opts = {
        PERL_PERTURB_KEYS => $mode,
        PERL_HASH_SEED_DEBUG => 1,  # needed for non DEBUGGING builds
    };
    for my $try (1 .. $repeat) {
        my $descr = sprintf "PERL_PERTURB_KEYS = %s, try %2d:", $mode, $try;
        my ( $out, $err )
            = my_runperl_and_capture( $base_opts, $print_keys );
        $err =~ /HASH_SEED = (0x[a-f0-9]+)/
            or die "Failed to extract hash seed from runperl_and_capture";
        my $seed = $1;
        my $run_opts = { %$base_opts, PERL_HASH_SEED => $seed };

        # now we have to run it again.
        my ( $out1, $err1, $err_got_data1, $rand_bits_data1 )
            = my_runperl_and_capture( $run_opts, $print_keys );

        # and once more, these two should be the same
        my ( $out2, $err2, $err_got_data2, $rand_bits_data2 )
            = my_runperl_and_capture( $run_opts, $print_keys );

        if ( $mode eq 'RANDOM' ) {
            isnt( $out1, $out2,
                "$descr results in different key order with the same keys"
            );
        }
        else {
            is( $out1, $out2,
                "$descr results in the same key order each time"
            );
        }
        SKIP: {
            skip "$descr not testing rand bits", 3
                if $mode eq "RANDOM";
            is ( 0+@$rand_bits_data1, 0+@$rand_bits_data2,
                "$descr same count of rand_bits_data entries each time");
            my $max_i = $#$rand_bits_data1 > $#$rand_bits_data2
                      ? $#$rand_bits_data1 : $#$rand_bits_data2;
            my $bad_idx;
            for my $i (0..$max_i) {
                if (($rand_bits_data2->[$i] // "") ne
                    ($rand_bits_data1->[$i] // "")) {
                    $bad_idx = $i;
                    last;
                }
            }
            is($bad_idx, undef,
                "$descr bad rand bits data index should be undef");
            if (defined $bad_idx) {
                # we use is() to see the differing data, but this test is
                # expected will fail - the description seems a little odd here,
                # but since it will always fail it makes sense in context.
                is($rand_bits_data2->[$bad_idx],$rand_bits_data1->[$bad_idx],
                    "$descr rand bits data is same at idx $bad_idx");
            } else {
                pass("$descr rand bits data does not differ");
            }
        }
        is( $err, $err2,
            "$descr debug output was consistent between runs"
        );
        ################################################################################
        # Using a different HASH_SEED
        $seed=~s/^0x//;
        my @chars = split //, $seed;
        $seed = "0x" . $seed;

        # increase by 1 the last digit (only)
        $chars[-1] = sprintf( "%x", ( hex( $chars[-1] ) + 1 ) % 16 );
        my $new_seed = "0x" . join '', @chars;
        isnt $new_seed, $seed, "$descr got a different seed";
        $run_opts->{PERL_HASH_SEED}= $new_seed;
        my ( $out2, $err2 )
            = my_runperl_and_capture( $run_opts, $print_keys );
        isnt( $out, $out2,
            "$descr results in different order with a different key"
        );
    }
    unlink_tempfiles();
}
