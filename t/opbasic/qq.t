#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# This file uses a specially crafted is() function rather than that found in
# t/test.pl or Test::More.  Hence, we place this file in directory t/opbasic.

print q(1..28
);

# This is() function is written to avoid ""
my $test = 1;
sub is {
    my($left, $right, $description) = @_;

    if ($left eq $right) {
      my $str = 'ok %d';
      if (defined $description) {
        $str .= " - $description";
      }
      $str .= "\n";
      printf $str, $test++;
      return 1;
    }
    foreach ($left, $right) {
      # Comment out these regexps to map non-printables to ord if the perl under
      # test is so broken that it is not helping
      s/([^-+A-Za-z_0-9])/sprintf q{'.chr(%d).'}, ord $1/ge;
      $_ = sprintf q('%s'), $_;
      s/^''\.//;
      s/\.''$//;
    }
    printf q(not ok %d - got %s expected %s
), $test++, $left, $right;

    printf q(# Failed test at line %d
), (caller)[2];

    return 0;
}

is ("\x53", chr 83, '\x53');
is ("\x4EE", chr (78) . 'E', '\x4EE');
no warnings 'digit';
is ("\x4i", chr (4) . 'i', '\x4i');	# This will warn
is ("\xh", chr (0) . 'h', '\xh');	# This will warn
is ("\xx", chr (0) . 'x', '\xx');	# This will warn
is ("\xx9", chr (0) . 'x9', '\xx9');	# This will warn. \x9 is tab in EBCDIC too?
is ("\x9_E", chr (9) . '_E', '\x9_E');	# This will warn
use warnings 'digit';

is ("\x{4E}", chr 78, '\x{4E}');
is ("\x{6_9}", chr 105, '\x{6_9}');
is ("\x{_6_3}", chr 99, '\x{_6_3}');
is ("\x{_6B}", chr 107, '\x{_6B}');

no warnings 'digit';
is ("\x{9__0}", chr 9, '\x{9__0}');		# multiple underscores not allowed; warns.
is ("\x{77_}", chr 119, '\x{9__0}');	# trailing underscore warns.
is ("\x{6FQ}z", chr (111) . 'z', '\x{6FQ}z'); # warns

is ("\x{0x4E}", chr 0, '\x{0x4E}'); # warns
is ("\x{x4E}", chr 0, '\x{x4E}');  # warns
use warnings 'digit';

is ("\x{0065}", chr 101, '\x{0065}');
is ("\x{000000000000000000000000000000000000000000000000000000000000000072}",
    chr 114, 'lots of zeroes');
is ("\x{0_06_5}", chr 101, '\x{0_06_5}');
is ("\x{1234}", chr 4660, '\x{1234}');
is ("\x{10FFFD}", chr 1114109, '\x{10FFFD}');
is ("\400", chr 0x100, '\400');
is ("\600", chr 0x180, '\600');
is ("\777", chr 0x1FF, '\777');
is ("a\o{120}b", "a" . chr(0x50) . "b", 'a\o{120}b');
is ("a\o{400}b", "a" . chr(0x100) . "b", 'a\o{400}b');
is ("a\o{1000}b", "a" . chr(0x200) . "b", 'a\o{1000}b');

# Maybe \x{} should be an error, but if not it should certainly mean \x{0}
# rather than anything else.
is ("\x{}", chr(0), '\x{}');
