#!./perl

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    skip_all_without_unicode_tables();
}

use 5.016;
use utf8;
#use open qw( :utf8 :std );
#no warnings qw(misc reserved);

my $chunks = 24;
my $total_tests = 65280;
my $tests;
#print STDERR __FILE__, ": ", __LINE__, ": $chunks\n";

{
    use integer;
    $tests = $total_tests / $chunks;
    $tests += $total_tests % $chunks if $::TESTCHUNK == $chunks - 1;
}
#print STDERR __FILE__, ": ", __LINE__, ": $tests\n";

plan (tests => $tests);

my $start = 0x100 + $::TESTCHUNK * $tests;
for my $i ($start .. $start + $tests - 1) {
   my $chr = chr($i);
   my $esc = sprintf("%x", $i);
   local $@;
   eval "my \$$chr = q<test>; \$$chr;";
   if ( $chr =~ /^\p{_Perl_IDStart}$/ ) {
      is($@, '', sprintf("\\x{%04x} is XIDS, works as a length-1 variable", $i));
   }
   else {
      like($@,
           qr/\QUnrecognized character \x{$esc};/,
           "\\x{$esc} isn't XIDS, illegal as a length-1 variable",
          )
   }
}
