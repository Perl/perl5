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

plan tests => 12;

our $TODO;
# Test that PERL_PERTURB_KEYS works as expected.  We check that we get the same
# results if we use PERL_PERTURB_KEYS = 0 or 2 and we reuse the seed from previous run.
my @print_keys = ( '-e', 'my %h; @h{"A".."Z", "a".."z"}=(); print keys %h' );
for my $mode (qw{NO RANDOM DETERMINISTIC}) {    # 0, 1 and 2 respectively
    my %base_opts;
    %base_opts = ( PERL_PERTURB_KEYS => $mode, PERL_HASH_SEED_DEBUG => 1 ),
        my ( $out, $err )
        = runperl_and_capture( {%base_opts}, [@print_keys] );
    if ( $err =~ /HASH_SEED = (0x[a-f0-9]+)/ ) {
        my $seed = $1;
        {
            # Reusing the same HASH_SEED
            my ( $out2, $err2 )
                = runperl_and_capture(
                { %base_opts, PERL_HASH_SEED => $seed },
                [@print_keys] );
            if ( $mode eq 'RANDOM' ) {
                isnt( $out, $out2,
                    "PERL_PERTURB_KEYS = $mode results in different key order with the same key"
                );
            }
            elsif ( $mode eq 'NO' ) {
                is( $out, $out2,
                    "PERL_PERTURB_KEYS = $mode allows one to recreate a random hash"
                );
            }
            elsif ( $mode eq 'DETERMINISTIC' ) {
                local $TODO = q[This test is flapping when using PERL_PERTURB_KEYS=DETERMINISTIC];
                is( $out, $out2,
                    "PERL_PERTURB_KEYS = $mode allows one to recreate a random hash"
                );
            }

            is( $err, $err2,
                "Got the same debug output when we set PERL_HASH_SEED and PERL_PERTURB_KEYS"
            );
        }
        {
            # Using a different HASH_SEED
            my @chars = split //, $seed;

            # increase by 1 the last digit (only)
            $chars[-1] = sprintf( "%x", ( hex( $chars[-1] ) + 1 ) % 15 );
            my $updated_seed = join '', @chars;
            isnt $updated_seed, $seed, "got a different seed";
            my ( $out2, $err2 )
                = runperl_and_capture(
                { %base_opts, PERL_HASH_SEED => $updated_seed },
                [@print_keys] );
            isnt( $out, $out2,
                "PERL_PERTURB_KEYS = $mode results in different order with a different key"
            );
        }
    }
}
