#!/usr/bin/perl -w

# test rounding, accuracy, precicion and fallback, round_mode and mixing
# of classes

use strict;
use Test;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 684;
  }

use Math::BigInt::Subclass;
use Math::BigFloat::Subclass;

use vars qw/$mbi $mbf/;

$mbi = 'Math::BigInt::Subclass';
$mbf = 'Math::BigFloat::Subclass';

require 't/mbimbf.inc';

