#!perl -w

BEGIN {
  chdir 't' if -d 't';
  @INC = '../lib';
  push @INC, "::lib:$MacPerl::Architecture:" if $^O eq 'MacOS';
  require Config; import Config;
  if ($Config{'extensions'} !~ /\bXS\/APItest\b/) {
    # Look, I'm using this fully-qualified variable more than once!
    my $arch = $MacPerl::Architecture;
    print "1..0 # Skip: XS::APItest was not built\n";
    exit 0;
  }
}

use Tie::Hash;

my @testkeys = ('N', chr 256);

my $temp = chr 258;
utf8::encode $temp;

my @keys = (@testkeys, $temp);
my (%hash, %tiehash);
tie %tiehash, 'Tie::StdHash';

@hash{@keys} = ();
@tiehash{@keys} = ();


use Test::More 'no_plan';

use_ok('XS::APItest');

sub test_present {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  ok (exists $hash{$key}, "hv_exists_ent present $printable");
  ok (XS::APItest::Hash::exists (\%hash, $key), "hv_exists present $printable");

  ok (exists $tiehash{$key}, "hv_exists_ent tie present  $printable");
  ok (XS::APItest::Hash::exists (\%tiehash, $key),
      "hv_exists tie present $printable");
}

sub test_absent {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  ok (!exists $hash{$key}, "hv_exists_ent absent $printable");
  ok (!XS::APItest::Hash::exists (\%hash, $key), "hv_exists absent $printable");

  ok (!exists $tiehash{$key}, "hv_exists_ent tie absent  $printable");
  ok (!XS::APItest::Hash::exists (\%tiehash, $key),
      "hv_exists tie absent $printable");
}

foreach my $key (@testkeys) {
  test_present ($key);

  my $lckey = lc $key;
  test_absent ($lckey);

  my $unikey = $key;
  utf8::encode $unikey;

  test_absent ($unikey) unless $unikey eq $key;
}

test_absent (chr 258);
