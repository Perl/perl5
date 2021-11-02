#!/usr/bin/perl
use v5.20.0;
use warnings;

use utf8 ();

BEGIN {
  @INC = '..' if -f '../TestInit.pm';
  require './test.pl';
}

use TestInit qw(T); # T is chdir to the top level

find_git_or_skip();

my $cdup = `git rev-parse --show-cdup`;
die "couldn't git-rev-parse --show-cdup\n" if $?;
chomp $cdup;

if (length $cdup) {
  chdir $cdup or die "can't chdir to git root: $!";
}

my @files = `git ls-files`;
die "couldn't git-ls-files\n" if $?;

chomp @files;

if (0) {
  # Is this a useful filter?  Should we test every file?  Do we contain binary
  # files, etc? -- rjbs, 2021-11-02
  my %is_interesting = map {; $_ => 1 } qw( bat c h pl pm sh t xs );
  @files = grep {; /\.([a-z]+)\z/ && $is_interesting{$1} } @files;
}

my @errors;

unless (@files) {
  fail("Something's wrong: no files to check?!");
  done_testing;
  exit;
}

FILE: for my $file (@files) {
  open my $fh, '<', "$file"
    or die "can't open $file: $!";

  while (defined (my $line = <$fh>)) {
    utf8::decode($line);
    push @errors, "$file at line $." if $line =~ /\p{Bidi_Control}/;
  }
}

if (@errors) {
  fail("Bidi control characters found in source");
  diag("Bidi control characters in $_") for @errors;
} else {
  pass("No bidi control characters found in source");
}

done_testing;
