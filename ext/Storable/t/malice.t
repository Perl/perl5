#!./perl -w

#
#  Copyright 2002, Larry Wall.
#
#  You may redistribute only under the same terms as Perl 5, as specified
#  in the README file that comes with the distribution.
#

# I'm trying to keep this test easily backwards compatible to 5.004, so no
# qr//;
# Currently using Test not Test::More, as Test is in core that far back.

# This test tries to craft malicious data to test out as many different
# error traps in Storable as possible
# It also acts as a test for read_header

sub BEGIN {
    if ($ENV{PERL_CORE}){
	chdir('t') if -d 't';
	@INC = '.';
	push @INC, '../lib';
    }
    require Config; import Config;
    if ($ENV{PERL_CORE} and $Config{'extensions'} !~ /\bStorable\b/) {
        print "1..0 # Skip: Storable was not built\n";
        exit 0;
    }
    # require 'lib/st-dump.pl';
}

use strict;
use vars qw($file_magic_str $other_magic $network_magic $major $minor
           $C_visible_byteorder);
$file_magic_str = 'pst0';
$other_magic = 7 + $Config{longsize};
$network_magic = 2;
$major = 2;
$minor = 5;

# Config.pm does games to figure out byteorder dynamically. In the process
# it creates an 8 digit entry on long long builds on 32 bit long systems.
# config.sh, config.h and therefore Storable.xs have a 4 digit entry.
$C_visible_byteorder = $Config{byteorder};
if ($Config{longsize} != $Config{ivsize}) {
  if ($C_visible_byteorder =~ /^1234/) {
    # Little endian
    substr ($C_visible_byteorder, $Config{longsize}) = '';
  } elsif ($C_visible_byteorder =~ /4321$/) {
    # Big endian
    $C_visible_byteorder = substr ($C_visible_byteorder, -$Config{longsize});
  } else {
    die "longs are $Config{longsize} bytes, IVs are $Config{ivsize}, byte order $C_visible_byteorder not regonised";
  }
}

use Test;
BEGIN { plan tests => 334 + $Config{longsize} * 4}

use Storable qw (store retrieve freeze thaw nstore nfreeze);

my $file = "malice.$$";
die "Temporary file 'malice.$$' already exists" if -e $file;

END { while (-f $file) {unlink $file or die "Can't unlink '$file': $!" }}

my %hash = (perl => 'rules');

sub test_hash {
  my $clone = shift;
  ok (ref $clone, "HASH", "Get hash back");
  ok (scalar keys %$clone, 1, "with 1 key");
  ok ((keys %$clone)[0], "perl", "which is correct");
  ok ($clone->{perl}, "rules");
}

sub test_header {
  my ($header, $isfile, $isnetorder) = @_;
  ok (!!$header->{file}, !!$isfile, "is file");
  ok ($header->{major}, $major, "major number");
  ok ($header->{minor}, $minor, "minor number");
  ok (!!$header->{netorder}, !!$isnetorder, "is network order");
  if ($isnetorder) {
    # Skip these
    for (1..5) {
      ok (1, 1, "Network order header has no sizes");
    }
  } else {
    ok ($header->{byteorder}, $C_visible_byteorder, "byte order");
    ok ($header->{intsize}, $Config{intsize}, "int size");
    ok ($header->{longsize}, $Config{longsize}, "long size");
    ok ($header->{ptrsize}, $Config{ptrsize}, "long size");
    ok ($header->{nvsize}, $Config{nvsize} || $Config{doublesize} || 8,
        "nv size"); # 5.00405 doesn't even have doublesize in config.
  }
}

sub store_and_retrieve {
  my $data = shift;
  unlink $file or die "Can't unlink '$file': $!";
  open FH, ">$file" or die "Can't open '$file': $!";
  binmode FH;
  print FH $data or die "Can't print to '$file': $!";
  close FH or die "Can't close '$file': $!";

  return  eval {retrieve $file};
}

sub freeze_and_thaw {
  my $data = shift;
  return eval {thaw $data};
}

sub test_truncated {
  my ($data, $sub, $magic_len, $what) = @_;
  for my $i (0 .. length ($data) - 1) {
    my $short = substr $data, 0, $i;

    my $clone = &$sub($short);
    ok (defined ($clone), '', "truncated $what to $i should fail");
    if ($i < $magic_len) {
      ok ($@, "/^Magic number checking on storable $what failed/",
          "Should croak with magic number warning");
    } else {
      ok ($@, "", "Should not set \$\@");
    }
  }
}

sub test_corrupt {
  my ($data, $sub, $what, $name) = @_;

  my $clone = &$sub($data);
  ok (defined ($clone), '', "$name $what should fail");
  ok ($@, $what, $name);
}

sub test_things {
  my ($contents, $sub, $what, $isnetwork) = @_;
  my $isfile = $what eq 'file';
  my $file_magic = $isfile ? length $file_magic_str : 0;

  my $header = Storable::read_magic ($contents);
  test_header ($header, $isfile, $isnetwork);

  # Test that if we re-write it, everything still works:
  my $clone = &$sub ($contents);

  ok ($@, "", "There should be no error");

  test_hash ($clone);

  # Now lets check the short version:
  test_truncated ($contents, $sub, $file_magic
                  + ($isnetwork ? $network_magic : $other_magic), $what);

  my $copy;
  if ($isfile) {
    $copy = $contents;
    substr ($copy, 0, 4) = 'iron';
    test_corrupt ($copy, $sub, "/^File is not a perl storable/",
                  "magic number");
  }

  $copy = $contents;
  my $minor1 = $header->{minor} + 1;
  substr ($copy, $file_magic + 1, 1) = chr $minor1;
  test_corrupt ($copy, $sub,
                "/^Storable binary image v$header->{major}\.$minor1 more recent than I am \\(v$header->{major}\.$header->{minor}\\)/",
                "higher minor");

  $copy = $contents;
  my $major1 = $header->{major} + 1;
  substr ($copy, $file_magic, 1) = chr 2*$major1;
  test_corrupt ($copy, $sub,
                "/^Storable binary image v$major1\.$header->{minor} more recent than I am \\(v$header->{major}\.$header->{minor}\\)/",
                "higher major");

  # Continue messing with the previous copy
  $minor1 = $header->{minor} - 1;
  substr ($copy, $file_magic + 1, 1) = chr $minor1;
  test_corrupt ($copy, $sub,
                "/^Storable binary image v$major1\.$minor1 more recent than I am \\(v$header->{major}\.$header->{minor}\\)/",
              "higher major, lower minor");

  my $where;
  if (!$isnetwork) {
    # All these are omitted from the network order header.
    # I'm not sure if it's correct to omit the byte size stuff.
    $copy = $contents;
    substr ($copy, $file_magic + 3, length $header->{byteorder})
      = reverse $header->{byteorder};

    test_corrupt ($copy, $sub, "/^Byte order is not compatible/",
                  "byte order");
    $where = $file_magic + 3 + length $header->{byteorder};
    foreach (['intsize', "Integer"],
             ['longsize', "Long integer"],
             ['ptrsize', "Pointer integer"],
             ['nvsize', "Double"]) {
      my ($key, $name) = @$_;
      $copy = $contents;
      substr ($copy, $where++, 1) = chr 0;
      test_corrupt ($copy, $sub, "/^$name size is not compatible/",
                    "$name size");
    }
  } else {
    $where = $file_magic + $network_magic;
  }

  # Just the header and a tag 255. As 26 is currently the highest tag, this
  # is "unexpected"
  $copy = substr ($contents, 0, $where) . chr 255;

  test_corrupt ($copy, $sub,
                "/^Corrupted storable $what \\(binary v$header->{major}.$header->{minor}\\)/",
                "bogus tag");
}

sub slurp {
  my $file = shift;
  local (*FH, $/);
  open FH, "<$file" or die "Can't open '$file': $!";
  binmode FH;
  my $contents = <FH>;
  die "Can't read $file: $!" unless defined $contents;
  return $contents;
}


ok (defined store(\%hash, $file));

my $expected = 20 + length ($file_magic_str) + $other_magic;
my $length = -s $file;

die "Don't seem to have written file '$file' as I can't get its length: $!"
  unless defined $file;

die "Expected file to be $expected bytes (sizeof long is $Config{longsize}) but it is $length"
  unless $length == $expected;

# Read the contents into memory:
my $contents = slurp $file;

# Test the original direct from disk
my $clone = retrieve $file;
test_hash ($clone);

# Then test it.
test_things($contents, \&store_and_retrieve, 'file');

# And now try almost everything again with a Storable string
my $stored = freeze \%hash;
test_things($stored, \&freeze_and_thaw, 'string');

# Network order.
unlink $file or die "Can't unlink '$file': $!";

ok (defined nstore(\%hash, $file));

$expected = 20 + length ($file_magic_str) + $network_magic;
$length = -s $file;

die "Don't seem to have written file '$file' as I can't get its length: $!"
  unless defined $file;

die "Expected file to be $expected bytes (sizeof long is $Config{longsize}) but it is $length"
  unless $length == $expected;

# Read the contents into memory:
$contents = slurp $file;

# Test the original direct from disk
$clone = retrieve $file;
test_hash ($clone);

# Then test it.
test_things($contents, \&store_and_retrieve, 'file', 1);

# And now try almost everything again with a Storable string
$stored = nfreeze \%hash;
test_things($stored, \&freeze_and_thaw, 'string', 1);
