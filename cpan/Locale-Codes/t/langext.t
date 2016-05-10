#!/usr/bin/perl

use warnings;
use strict;
require 5.002;

my($runtests,$dir,$tdir);
$::type          = '';
$::module        = '';
$::tests         = '';

$::type   = 'langext';
$::module = 'Locale::Codes::LangExt';

$runtests=shift(@ARGV);
if ( -f "t/testfunc.pl" ) {
  require "t/testfunc.pl";
  require "t/vals.pl";
  require "t/vals_langext.pl";
  $dir="./lib";
  $tdir="t";
} elsif ( -f "testfunc.pl" ) {
  require "testfunc.pl";
  require "vals.pl";
  require "vals_langext.pl";
  $dir="../lib";
  $tdir=".";
} else {
  die "ERROR: cannot find testfunc.pl\n";
}

unshift(@INC,$dir);

print "langext...\n";
test_Func(\&test,$::tests,$runtests);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
