#!/usr/bin/perl -w

# test rounding, accuracy, precicion and fallback, round_mode and mixing
# of classes under BareCalc

use strict;
use Test;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 684
    + 1;		# our own tests
  }

print "# ",Math::BigInt->config()->{lib},"\n";

use Math::BigInt lib => 'BareCalc';
use Math::BigFloat lib => 'BareCalc';

use vars qw/$mbi $mbf/;

$mbi = 'Math::BigInt';
$mbf = 'Math::BigFloat';

ok (Math::BigInt->config()->{lib},'Math::BigInt::BareCalc');

require 't/mbimbf.inc';
