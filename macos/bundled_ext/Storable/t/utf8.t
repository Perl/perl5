#!./perl

# $Id: utf8.t,v 1.0.1.2 2000/09/28 21:44:17 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the same terms as Perl 5, as specified
#  in the README file that comes with the distribution.
#
# $Log: utf8.t,v $
# Revision 1.0.1.2  2000/09/28 21:44:17  ram
# patch2: fixed stupid typo
#
# Revision 1.0.1.1  2000/09/17 16:48:12  ram
# patch1: created.
#
#

use Storable qw(thaw freeze);

if ($] < 5.006) {
	print "1..0\n";
	exit 0;
}

require 't/dump.pl';
sub ok;

print "1..1\n";

$x = chr(1234);
ok 1, $x eq ${thaw freeze \$x};

