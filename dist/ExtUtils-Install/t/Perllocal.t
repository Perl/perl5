#!/usr/bin/perl -w

# Test ExtUtils::Install.

use strict;
use Test::More tests => 10;
use File::Spec;
BEGIN { use_ok('ExtUtils::Perllocal') }

my $datafile = File::Spec->catdir("t", "data", "perllocal.pod");
$datafile = File::Spec->catdir("data", "perllocal.pod") if not -f $datafile;
ok(-f $datafile, "test file exists");

my $pl = ExtUtils::Perllocal->new(file => $datafile);
isa_ok($pl, 'ExtUtils::Perllocal');
my @entries = $pl->get_entries();
is(scalar(@entries), 16, "Found all entries");

my $pod = join '', map $_->as_pod, @entries;
is($pod, slurp($datafile), "rountrip okay");

my $testfile = $datafile . '.tmp';
$SIG{INT} = $SIG{HUP} = $SIG{TERM} = sub {
  unlink $testfile;
  exit(1);
};

END {unlink $testfile}

open OFH, ">$testfile"
  or die "Cannot open $testfile for writing: $!";

print OFH $pod;
close OFH;

$pl = ExtUtils::Perllocal->new(file => $testfile);
my %entrydata = (
  type => 'Foo',
  name => 'The::Name',
  'time' => 1304973319,
  data => {d1 => 'foo', bar => 'baz'},
);
$pl->append_entry(ExtUtils::Perllocal::Entry->new(%entrydata));

$pl = ExtUtils::Perllocal->new(file => $testfile);
@entries = $pl->get_entries();
is(scalar(@entries), 17, "Found all entries + 1");
my $e = $entries[-1];
is($e->type, $entrydata{type});
is($e->name, $entrydata{name});
is($e->time, $entrydata{time});
is_deeply($e->data, $entrydata{data});
unlink($testfile);

sub slurp {
  my $datafile = shift;
  open FH, "<$datafile" or die $!;
  local $/;
  my $tmp = <FH>;
  close FH;
  $tmp
}
