#!/usr/bin/perl -w

# Test that @INC is propogated from the harness process to the test
# process.

use strict;
use lib 't/lib';

sub has_crazy_patch {
    my $sentinel = 'blirpzoffle';
    local $ENV{PERL5LIB} = $sentinel;
    my $command = join ' ',
      map {qq{"$_"}} ( $^X, '-e', 'print join q(:), @INC' );
    my $path = `$command`;
    my @got = ( $path =~ /($sentinel)/g );
    return @got > 1;
}

use Test::More (
      $^O eq 'VMS' ? ( skip_all => 'VMS' )
    : has_crazy_patch() ? ( skip_all => 'Incompatible @INC patch' )
    : ( tests => 2 )
);

use Data::Dumper;
use Test::Harness;

# Change @INC so we ensure it's preserved.
use lib 'wibble';

# TODO: Disabled until we find out why it's breaking on Windows. It's
# not strictly a TODO because it seems pretty likely that it's a Windows
# problem rather than a problem with Test::Harness.

# Put a stock directory near the beginning.
# use lib $INC[$#INC-2];

my $inc = Data::Dumper->new( [ \@INC ] )->Terse(1)->Purity(1)->Dump;
my $taint_inc
  = Data::Dumper->new( [ [ grep { $_ ne '.' } @INC ] ] )->Terse(1)->Purity(1)
  ->Dump;

my $test_template = <<'END';
#!/usr/bin/perl %s

use Test::More tests => 2;

sub _strip_dups {
    my %%dups;
    # Drop '.' which sneaks in on some platforms
    return grep { $_ ne '.' } grep { !$dups{$_}++ } @_;
}

# Make sure we did something sensible with PERL5LIB
like $ENV{PERL5LIB}, qr{wibble};

is_deeply(
    [_strip_dups(@INC)],
    [_strip_dups(@{%s})],
    '@INC propagated to test'
) or do {
    diag join ",\n", _strip_dups(@INC);
    diag '-----------------';
    diag join ",\n", _strip_dups(@{%s});
};
END

open TEST, ">inc_check.t.tmp";
printf TEST $test_template, '', $inc, $inc;
close TEST;

open TEST, ">inc_check_taint.t.tmp";
printf TEST $test_template, '-T', $taint_inc, $taint_inc;
close TEST;
END { 1 while unlink 'inc_check_taint.t.tmp', 'inc_check.t.tmp'; }

for my $test ( 'inc_check_taint.t.tmp', 'inc_check.t.tmp' ) {
    my ( $tot, $failed ) = Test::Harness::execute_tests( tests => [$test] );
    is $tot->{bad}, 0;
}
1;
