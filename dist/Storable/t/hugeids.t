#!./perl

# We do all of the work in child processes here to ensure that any
# memory used is released immediately.

# These tests use ridiculous amounts of memory and CPU.

use strict;
use warnings;

use Config;
use Storable qw(store_fd retrieve_fd);
use Test::More;
use File::Temp qw(tempfile);
use Devel::Peek;

BEGIN {
    plan skip_all => 'Storable was not built'
        if $ENV{PERL_CORE} && $Config{'extensions'} !~ /\b Storable \b/x;
    plan skip_all => 'Need 64-bit pointers for this test'
        if $Config{ptrsize} < 8 and $] > 5.013;
    plan skip_all => 'Need 64-bit int for this test on older versions'
        if $Config{uvsize} < 8 and $] < 5.013;
    plan skip_all => 'Need ~34 GiB memory for this test, set PERL_TEST_MEMORY >= 34'
        if !$ENV{PERL_TEST_MEMORY} || $ENV{PERL_TEST_MEMORY} < 34;
    plan skip_all => 'These tests are slow, set PERL_RUN_SLOW_TESTS'
        unless $ENV{PERL_RUN_SLOW_TESTS};
    plan skip_all => "Need fork for this test",
        unless $Config{d_fork};
}

plan tests => 4;

my $skips = $ENV{PERL_STORABLE_SKIP_ID_TEST} || '';

SKIP:
{
    # test object ids between the 2G and 4G marks

    # We now output these as 64-bit ids since older Storables treat
    # the object id incorrectly and product an incorrect output
    # structure.
    #
    # This uses a lot of memory, we use child processes to ensure the
    # memory is freed 
    $ENV{PERL_TEST_MEMORY} >= 34
        or skip "Not enough memory to test 2G-4G object ids", 2;
    $skips =~ /\b2g\b/
      and skip "You requested this test be skipped", 2;
    # IPC::Run would be handy here
    my $stored;
    if (defined(my $pid = open(my $fh, "-|"))) {
        unless ($pid) {
	    # child
	    open my $cfh, "|-", "gzip"
	      or die "Cannot pipe to gzip: $!";
	    binmode $cfh;
	    make_2g_data($cfh);
	    exit;
	}
	# parent
	$stored = do { local $/; <$fh> };
	close $fh;
    }
    else {
        skip "Cannot fork", 2;
    }
    ok($stored, "we got 2G+ id output data");
    my ($tfh, $tname) = tempfile();
    print $tfh $stored;
    close $tfh;
    
    if (defined(my $pid = open(my $fh, "-|"))) {
        unless ($pid) {
	    # child
	    open my $bfh, "-|", "gunzip <$tname"
	      or die "Cannot pipe from gunzip: $!";
	    binmode $bfh;
	    check_2g_data($bfh);
	    exit;
        }
	my $out = do { local $/; <$fh> };
	chomp $out;
	is($out, "OK", "check 2G+ id result");
    }
    else {
        skip "Cannot fork", 1;
    }
}

SKIP:
{
    # test object ids over 4G

    $ENV{PERL_TEST_MEMORY} >= 70
        or skip "Not enough memory to test 2G-4G object ids", 2;
    $skips =~ /\b4g\b/
      and skip "You requested this test be skipped", 2;
    # IPC::Run would be handy here
    my $stored;
    if (defined(my $pid = open(my $fh, "-|"))) {
        unless ($pid) {
	    # child
	    open my $cfh, "|-", "gzip"
	      or die "Cannot pipe to gzip: $!";
	    binmode $cfh;
	    make_4g_data($cfh);
	    exit;
	}
	# parent
	$stored = do { local $/; <$fh> };
	close $fh;
    }
    else {
        skip "Cannot fork", 2;
    }
    ok($stored, "we got 4G+ id output data");
    my ($tfh, $tname) = tempfile();
    print $tfh $stored;
    close $tfh;
    
    if (defined(my $pid = open(my $fh, "-|"))) {
        unless ($pid) {
	    # child
	    open my $bfh, "-|", "gunzip <$tname"
	      or die "Cannot pipe from gunzip: $!";
	    binmode $bfh;
	    check_4g_data($bfh);
	    exit;
        }
	my $out = do { local $/; <$fh> };
	chomp $out;
	is($out, "OK", "check 4G+ id result");
    }
    else {
        skip "Cannot fork", 1;
    }
}



sub make_2g_data {
  my ($fh) = @_;
  my @x;
  my $y = 1;
  my $z = 2;
  my $g2 = 0x80000000;
  $x[0] = \$y;
  $x[$g2] = \$y;
  $x[$g2+1] = \$z;
  $x[$g2+2] = \$z;
  store_fd(\@x, $fh);
}

sub check_2g_data {
  my ($fh) = @_;
  my $x = retrieve_fd($fh);
  my $g2 = 0x80000000;
  $x->[0] == $x->[$g2]
    or die "First entry mismatch";
  $x->[$g2+1] == $x->[$g2+2]
    or die "2G+ entry mismatch";
  print "OK";
}

sub make_4g_data {
  my ($fh) = @_;
  my @x;
  my $y = 1;
  my $z = 2;
  my $g4 = 2*0x80000000;
  $x[0] = \$y;
  $x[$g4] = \$y;
  $x[$g4+1] = \$z;
  $x[$g4+2] = \$z;
  store_fd(\@x, $fh);
}

sub check_4g_data {
  my ($fh) = @_;
  my $x = retrieve_fd($fh);
  my $g4 = 2*0x80000000;
  $x->[0] == $x->[$g4]
    or die "First entry mismatch";
  $x->[$g4+1] == $x->[$g4+2]
    or die "4G+ entry mismatch";
  print "OK";
}
