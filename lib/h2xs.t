#!./perl -w

# Some quick tests to see if h2xs actually runs and creates files as 
# expected.  File contents include date stamps and/or usernames
# hence are not checked.  File existence is checked with -e though.
# This test depends on File::Path::rmtree() to clean up with.
#  - pvhp

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# use strict; # we are not really testing this
use File::Path;  # for cleaning up with rmtree()
use Test;


my $extracted_program = '../utils/h2xs'; # unix, nt, ...
if ($^O eq 'VMS') { $extracted_program = '[-.utils]h2xs.com'; }
if ($^O eq 'MacOS') { $extracted_program = '::utils:h2xs'; }
if (!(-e $extracted_program)) {
    print "1..0 # Skip: $extracted_program was not built\n";
    exit 0;
}
# You might also wish to bail out if your perl platform does not
# do `$^X -e 'warn "Writing h2xst"' 2>&1`; duplicity.

my $dupe = '2>&1'; # ok on unix, nt, VMS, ...
my $lib = '"-I../lib"'; # ok on unix, nt, The extra \" are for VMS
# The >&1 would create a file named &1 on MPW (STDERR && STDOUT are
# already merged).
if ($^O eq 'MacOS') {
    $dupe = '';
    $lib = '-x -I::lib:'; # -x overcomes MPW $Config{startperl} anomaly
}
# $name should differ from system header file names and must
# not already be found in the t/ subdirectory for perl.
my $name = 'h2xst';
my $header = "$name.h";

my @tests = (
"-f -n $name", <<"EOXSFILES",
Writing $name/$name.pm
Writing $name/$name.xs
Writing $name/Makefile.PL
Writing $name/README
Writing $name/t/1.t
Writing $name/Changes
Writing $name/MANIFEST
EOXSFILES

"\"-X\" -f -n $name", <<"EONOXSFILES",
Writing $name/$name.pm
Writing $name/Makefile.PL
Writing $name/README
Writing $name/t/1.t
Writing $name/Changes
Writing $name/MANIFEST
EONOXSFILES

"-f -n $name $header", <<"EOXSFILES",
Writing $name/$name.pm
Writing $name/$name.xs
Writing $name/Makefile.PL
Writing $name/README
Writing $name/t/1.t
Writing $name/Changes
Writing $name/MANIFEST
EOXSFILES
);

my $total_tests = 3; # opening, closing and deleting the header file.
for (my $i = $#tests; $i > 0; $i-=2) {
  # 1 test for running it, 1 test for the expected result, and 1 for each file
  # use the () to force list context and hence count the number of matches.
  $total_tests += 2 + (() = $tests[$i] =~ /(Writing)/sg);
}

plan tests => $total_tests;

ok (open (HEADER, ">$header"));
print HEADER <<HEADER or die $!;
#define Camel 2
#define Dromedary 1
HEADER
ok (close (HEADER));

while (my ($args, $expectation) = splice @tests, 0, 2) {
  # h2xs warns about what it is writing hence the (possibly unportable)
  # 2>&1 dupe:
  # does it run?
  my $prog = "$^X $lib $extracted_program $args $dupe";
  @result = `$prog`;
  ok ($?, 0, "running $prog");
  $result = join("",@result);

  # accomodate MPW # comment character prependage
  if ($^O eq 'MacOS') {
    $result =~ s/#\s*//gs;
  }

  #print "# expectation is >$expectation<\n";
  #print "# result is >$result<\n";
  # Was the output the list of files that were expected?
  ok ($result, $expectation, "running $prog");

  $expectation =~ s/Writing //; # remove leader
  foreach (split(/Writing /,$expectation)) {
    chomp;  # remove \n
    if ($^O eq 'MacOS') {
      $_ = ':' . join(':',split(/\//,$_));
      $_ =~ s/$name:t:1.t/$name:t\/1.t/; # is this an h2xs bug?
    }
    ok (-e $_, 1, "$_ missing");
  }

  # clean up
  rmtree($name);
}

ok (unlink ($header), 1, $!);
