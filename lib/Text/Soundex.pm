package Text::Soundex;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&soundex $soundex_nocode);

# $Id: soundex.pl,v 1.2 1994/03/24 00:30:27 mike Exp $
#
# Implementation of soundex algorithm as described by Knuth in volume
# 3 of The Art of Computer Programming, with ideas stolen from Ian
# Phillips <ian@pipex.net>.
#
# Mike Stok <Mike.Stok@meiko.concord.ma.us>, 2 March 1994.
#
# Knuth's test cases are:
# 
# Euler, Ellery -> E460
# Gauss, Ghosh -> G200
# Hilbert, Heilbronn -> H416
# Knuth, Kant -> K530
# Lloyd, Ladd -> L300
# Lukasiewicz, Lissajous -> L222
#
# $Log: soundex.pl,v $
# Revision 1.2  1994/03/24  00:30:27  mike
# Subtle bug (any excuse :-) spotted by Rich Pinder <rpinder@hsc.usc.edu>
# in the way I handles leasing characters which were different but had
# the same soundex code.  This showed up comparing it with Oracle's
# soundex output.
#
# Revision 1.1  1994/03/02  13:01:30  mike
# Initial revision
#
#
##############################################################################

# $soundex_nocode is used to indicate a string doesn't have a soundex
# code, I like undef other people may want to set it to 'Z000'.

$soundex_nocode = undef;

# soundex
#
# usage:
#
# @codes = &soundex (@wordList);
# $code = &soundex ($word);
#
# This strenuously avoids 0

sub soundex
{
  local (@s, $f, $fc, $_) = @_;

  foreach (@s)
  {
    tr/a-z/A-Z/;
    tr/A-Z//cd;

    if ($_ eq '')
    {
      $_ = $soundex_nocode;
    }
    else
    {
      ($f) = /^(.)/;
      tr/AEHIOUWYBFPVCGJKQSXZDTLMNR/00000000111122222222334556/;
      ($fc) = /^(.)/;
      s/^$fc+//;
      tr///cs;
      tr/0//d;
      $_ = $f . $_ . '000';
      s/^(.{4}).*/$1/;
    }
  }

  wantarray ? @s : shift @s;
}

1;

