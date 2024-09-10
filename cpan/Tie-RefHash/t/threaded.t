#!/usr/bin/perl -T -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;


BEGIN {
    # this is sucky because threads.pm has to be loaded before Test::Builder
  use Config;

  if ( $^O eq 'MSWin32' ) {
    print "1..0 # Skip -- this test is generally broken on windows for unknown reasons. If you can help debug this patches would be very welcome.\n";
    exit 0;
  }
  if ( $Config{usethreads} and !$Config{use5005threads}
      and eval { +require threads; threads->import; 1 }
  ) {
    print "1..18\n";
  } else {
    print "1..0 # Skip -- threads aren't enabled in your perl";
    exit 0;
  }
}

use Scalar::Util qw(weaken);
use Tie::RefHash;

$\ = "\n";
sub ok ($$) {
  print ( ( $_[0] ? "" : "not " ), "ok - $_[1]" );
}

sub is ($$$) {
  print ( ( ( ($_[0]||'') eq ($_[1]||'') ) ? "" : "not "), "ok - $_[2]" );
}

tie my %hash, "Tie::RefHash";

my $r1 = {};
my $r2 = [];
my $v1 = "foo";

$hash{$r1} = "hash";
$hash{$r2} = "array";
$hash{$v1} = "string";

is( $hash{$v1}, "string", "fetch by string before clone ($v1)" );
is( $hash{$r1}, "hash", "fetch by ref before clone ($r1)" );
is( $hash{$r2}, "array", "fetch by ref before clone ($r2)" );

my $th = threads->create(sub {
  is( scalar keys %hash, 3, "key count is OK" );

  ok( exists $hash{$v1}, "string key exists ($v1)" );
  is( $hash{$v1}, "string", "fetch by string" );

  ok( exists $hash{$r1}, "ref key exists ($r1)" );
  is( $hash{$r1}, "hash", "fetch by ref" );

  ok( exists $hash{$r2}, "ref key exists ($r2)" );
  is( $hash{$r2}, "array", "fetch by ref" );

  is( join("\0",sort keys %hash), join("\0",sort $r1, $r2, $v1), "keys are ok" );
});

$th->join;

is( $hash{$v1}, "string", "fetch by string after clone, orig thread ($v1)" );
is( $hash{$r1}, "hash", "fetch by ref after clone ($r1)" );
is( $hash{$r2}, "array", "fetch by ref after clone ($r2)" );

{
    # RT 64025

    my $ref;
    {
        tie my %local_hash, "Tie::RefHash";
        $ref = tied %local_hash;
        weaken $ref;
        is( ref($ref), "Tie::RefHash", "[attempt 1] tie object exists" );
    }
    ok( !defined($ref), "[attempt 2] tie object is gone after hash goes out of scope" );

    {
        tie my %local_hash, "Tie::RefHash";
        $ref = tied %local_hash;
        weaken $ref;
        is( ref($ref), "Tie::RefHash", "[attempt 2] tie object exists" );

        for my $i (1 .. 1_000) {
            tie my %tmp, "Tie::RefHash";  # churn
        }
    }
    ok( !defined($ref), "[attempt 2] tie object is gone after hash goes out of scope" );
}
