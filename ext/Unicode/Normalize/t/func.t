# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {
    if (ord("A") == 193) {
	print "1..0 # Unicode::Normalize not ported to EBCDIC\n";
	exit 0;
    }
}

#########################

use Test;
use strict;
use warnings;
BEGIN { plan tests => 6 };
use Unicode::Normalize qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

print getCombinClass(   0) == 0
   && getCombinClass( 768) == 230
   && getCombinClass(1809) == 36
#  && getCombinClass(119143) == 1
  ? "ok" : "not ok", " 2\n";

print ! defined getCanon( 0)
   && ! defined getCanon(41)
   && getCanon(0x00C0) eq pack('U*', 0x0041, 0x0300)
   && getCanon(0x00EF) eq pack('U*', 0x0069, 0x0308)
   && getCanon(0x304C) eq pack('U*', 0x304B, 0x3099)
   && getCanon(0x1EA4) eq pack('U*', 0x0041, 0x0302, 0x0301)
   && getCanon(0x1F82) eq "\x{03B1}\x{0313}\x{0300}\x{0345}"
   && getCanon(0x1FAF) eq pack('U*', 0x03A9, 0x0314, 0x0342, 0x0345)
   && getCanon(0xAC00) eq pack('U*', 0x1100, 0x1161)
   && getCanon(0xAE00) eq pack('U*', 0x1100, 0x1173, 0x11AF)
   && ! defined getCanon(0x212C)
   && ! defined getCanon(0x3243)
   && getCanon(0xFA2D) eq pack('U*', 0x9DB4)
  ? "ok" : "not ok", " 3\n";

print ! defined getCompat( 0)
   && ! defined getCompat(41)
   && getCompat(0x00C0) eq pack('U*', 0x0041, 0x0300)
   && getCompat(0x00EF) eq pack('U*', 0x0069, 0x0308)
   && getCompat(0x304C) eq pack('U*', 0x304B, 0x3099)
   && getCompat(0x1EA4) eq pack('U*', 0x0041, 0x0302, 0x0301)
   && getCompat(0x1F82) eq pack('U*', 0x03B1, 0x0313, 0x0300, 0x0345)
   && getCompat(0x1FAF) eq pack('U*', 0x03A9, 0x0314, 0x0342, 0x0345)
   && getCompat(0x212C) eq pack('U*', 0x0042)
   && getCompat(0x3243) eq pack('U*', 0x0028, 0x81F3, 0x0029)
   && getCompat(0xAC00) eq pack('U*', 0x1100, 0x1161)
   && getCompat(0xAE00) eq pack('U*', 0x1100, 0x1173, 0x11AF)
   && getCompat(0xFA2D) eq pack('U*', 0x9DB4)
  ? "ok" : "not ok", " 4\n";

print ! defined getComposite( 0,  0)
   && ! defined getComposite( 0, 41)
   && ! defined getComposite(41,  0)
   && ! defined getComposite(41, 41)
   && ! defined getComposite(12, 0x0300)
   && ! defined getComposite(0x0055, 0xFF00)
   && 0x00C0 == getComposite(0x0041, 0x0300)
   && 0x00D9 == getComposite(0x0055, 0x0300)
   && 0x1E14 == getComposite(0x0112, 0x0300)
   && 0xAC00 == getComposite(0x1100, 0x1161)
   && 0xADF8 == getComposite(0x1100, 0x1173)
   && ! defined getComposite(0x1100, 0x11AF)
   && ! defined getComposite(0x1173, 0x11AF)
   && 0xAE00 == getComposite(0xADF8, 0x11AF)
  ? "ok" : "not ok", " 5\n";

print ! isExclusion( 0)
   && ! isExclusion(41)
   && isExclusion(2392)
   && isExclusion(3907)
   && isExclusion(64334)
  ? "ok" : "not ok", " 6\n";

