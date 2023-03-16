#!perl
BEGIN {
    chdir 't' if -d 't';
    @INC = "../lib";
    require './test.pl';
}

use strict;
use Config qw(%Config);
use XS::APItest;

# memory usage checked with top
$ENV{PERL_TEST_MEMORY} >= 60
    or skip_all("Need ~60GB for this test");
$Config{ptrsize} >= 8
    or skip_all("Need 64-bit pointers for this test");

my @x;
$x[0x8000_0000] = "Hello";

my @tests =
  (
      [ mark => sub
        {
            # unlike the grep example this avoids the mark manipulation done by grep
            # so it's more of a pure mark type test
            # it also fails/succeeds a lot faster
            my $count = () =  (x(), z());
            is($count, 0x8000_0002, "got expected (large) list size");
        },
      ],
      [ xssize => sub
        {
            # check XS gets the right numbers in our predefined variables
            # returned ~ -2G before fix
            my $count = XS::APItest::xs_items(x(), z());
            is($count, 0x8000_0002, "got expected XS list size");
        }
      ],
      [ listsub => sub
        {
            my $last = ( x() )[-1];
            is($last, "Hello", "list subscripting");

            my ($first, $last2, $last1) = ( "first", x(), "Goodbye" )[0, -2, -1];
            is($first, "first", "list subscripting in list context (0)");
            is($last2, "Hello", "list subscripting in list context (-2)");
            is($last1, "Goodbye", "list subscripting in list context (-1)");
        }
      ],
      [ iterctx => sub
        {
            # the iter context had an I32 stack offset
            my $last = ( x(), iter() )[-1];
            is($last, "abc", "check iteration not confused");
        }
      ],
      [ split => sub
        {
            # split had an I32 base offset
            # this paniced with "Split loop"
            my $count = () = ( x(), do_split("ABC") );
            is($count, 0x8000_0004, "split base index");
            # it would be nice to test split returning >2G (or >4G) items, but
            # I don't have the memory needed
        }
      ],
      [ xsload => sub
        {
            # I expect this to crash if buggy
            my $count = () = (x(), loader());
            is($count, 0x8000_0001, "check loading XS with large stack");
        }
      ],
      [ pp_list => sub
        {
            my $l = ( x(), list2() )[-1];
            is($l, 2, "pp_list mark handling");
        }
       ],
      [
          chomp_av => sub {
              # not really stack related, but is 32-bit related
              local $x[-1] = "Hello\n";
              chomp(@x);
              is($x[-1], "Hello", "chomp on a large array");
          }
         ],
      [
          grepwhile => sub {
            SKIP: {
                  skip("This test is even slower - define PERL_RUN_SLOW_TESTS to run me", 1)
                    unless $ENV{PERL_RUN_SLOW_TESTS};
                  # grep ..., @x used too much memory
                  my $count = grep 1, ( (undef) x 0x7FFF_FFFF, 1, 1 );
                  is($count, 0x8000_0001, "grepwhile item count");
              }
          }
      ],
     );

# these tests are slow, let someone debug them one at a time
my %enabled = map { $_ => 1 } @ARGV;
for my $test (@tests) {
    my ($id, $code) = @$test;
    if (!@ARGV || $enabled{$id}) {
        note($id);
        $code->();
    }
}

done_testing();

sub x { @x }

sub z { 1 }

sub iter {
    my $result = '';
    my $count = 0;
    for my $item (qw(a b c)) {
        $result .= $item;
        die "iteration bug" if ++$count > 5;
    }
    $result;
}

sub do_split {
    return split //, $_[0];
}

sub loader {
    require Cwd;
    ();
}

sub list2 {
    scalar list(1);
}

sub list {
    return shift() ? (1, 2) : (2, 1);
}
