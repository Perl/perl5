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

my $utf8_for_258 = chr 258;
utf8::encode $utf8_for_258;

my @keys = (@testkeys, $utf8_for_258);
my (%hash, %tiehash);
tie %tiehash, 'Tie::StdHash';

@hash{@keys} = @keys;
@tiehash{@keys} = @keys;


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

sub test_delete_present {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  my $copy = {%hash};
  is (delete $copy->{$key}, $key, "hv_delete_ent present $printable");
  $copy = {%hash};
  is (XS::APItest::Hash::delete ($copy, $key), $key,
      "hv_delete present $printable");

  $copy = {};
  tie %$copy, 'Tie::StdHash';
  %$copy = %tiehash;
  is (delete $copy->{$key}, $key, "hv_delete_ent tie present $printable");

  %$copy = %tiehash;
  is (XS::APItest::Hash::delete ($copy, $key), $key,
      "hv_delete tie present $printable");
}

sub test_delete_absent {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  my $copy = {%hash};
  is (delete $copy->{$key}, undef, "hv_delete_ent absent $printable");
  $copy = {%hash};
  is (XS::APItest::Hash::delete ($copy, $key), undef,
      "hv_delete absent $printable");

  $copy = {};
  tie %$copy, 'Tie::StdHash';
  %$copy = %tiehash;
  is (delete $copy->{$key}, undef, "hv_delete_ent tie absent $printable");

  %$copy = %tiehash;
  is (XS::APItest::Hash::delete ($copy, $key), undef,
      "hv_delete tie absent $printable");
}

sub brute_force_exists {
  my ($hash, $key) = @_;
  foreach (keys %$hash) {
    return 1 if $key eq $_;
  }
  return 0;
}

sub test_store {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  # We are cheating - hv_store returns NULL for a store into an empty
  # tied hash. This isn't helpful here.

  my %h1 = (a=>'cheat');
  is ($h1{$key} = 1, 1); 
  ok (brute_force_exists (\%h1, $key), "hv_store_ent $printable");
  my %h2 = (a=>'cheat');
  is (XS::APItest::Hash::store(\%h2, $key,  1), 1);
  ok (brute_force_exists (\%h2, $key), "hv_store $printable");
  my %h3 = (a=>'cheat');
  tie %h3, 'Tie::StdHash';
  is ($h3{$key} = 1, 1); 
  ok (brute_force_exists (\%h3, $key), "hv_store_ent tie $printable");

  my %h4 = (a=>'cheat');
  tie %h4, 'Tie::StdHash';
  is (XS::APItest::Hash::store(\%h4, $key, 1), 1);
  ok (brute_force_exists (\%h4, $key), "hv_store tie $printable");
}

sub test_fetch_present {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  is ($hash{$key}, $key, "hv_fetch_ent present $printable");
  is (XS::APItest::Hash::fetch (\%hash, $key), $key,
      "hv_fetch present $printable");

  is ($tiehash{$key}, $key, "hv_fetch_ent tie  present $printable");
  is (XS::APItest::Hash::fetch (\%tiehash, $key), $key,
      "hv_fetch tie present $printable");
}

sub test_fetch_absent {
  my $key = shift;
  my $printable = join ',', map {ord} split //, $key;

  is ($hash{$key}, undef, "hv_fetch_ent absent $printable");
  is (XS::APItest::Hash::fetch (\%hash, $key), undef,
      "hv_fetch absent $printable");

  is ($tiehash{$key}, undef, "hv_fetch_ent tie  absent $printable");
  is (XS::APItest::Hash::fetch (\%tiehash, $key), undef,
      "hv_fetch tie absent $printable");
}

foreach my $key (@testkeys) {
  test_present ($key);
  test_fetch_present ($key);
  test_delete_present ($key);

  test_store ($key);

  my $lckey = lc $key;
  test_absent ($lckey);
  test_fetch_absent ($lckey);
  test_delete_absent ($lckey);

  my $unikey = $key;
  utf8::encode $unikey;

  next if $unikey eq $key;

  test_absent ($unikey);
  test_fetch_absent ($unikey);
  test_delete_absent ($unikey);
}

# hv_exists was buggy for tied hashes, in that the raw utf8 key was being
# used - the utf8 flag was being lost.
test_absent (chr 258);
test_fetch_absent (chr 258);
test_delete_absent (chr 258);

{
  my %h = (a=>'cheat');
  tie %h, 'Tie::StdHash';
  is (XS::APItest::Hash::store(\%h, chr 258,  1), 1);

  ok (!exists $h{$utf8_for_258},
      "hv_store doesn't insert a key with the raw utf8 on a tied hash");
}
