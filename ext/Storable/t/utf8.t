#!./perl -w

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

sub BEGIN {
    if ($] < 5.006) {
	print "1..0 # Skip: no utf8 support\n";
	exit 0;
    }
    if ($ENV{PERL_CORE}){
	chdir('t') if -d 't';
	@INC = '.'; 
	push @INC, '../lib';
    }
    require Config; import Config;
    if ($ENV{PERL_CORE} and $Config{'extensions'} !~ /\bStorable\b/) {
        print "1..0 # Skip: Storable was not built\n";
        exit 0;
    }
    require 'lib/st-dump.pl';
}

use strict;
sub ok;

use Storable qw(thaw freeze);

print "1..3\n";

my $x = chr(1234);
ok 1, $x eq ${thaw freeze \$x};

# Long scalar
$x = join '', map {chr $_} (0..1023);
ok 2, $x eq ${thaw freeze \$x};

# Char in the range 127-255 (probably) in utf8
$x = chr (175) . chr (256);
chop $x;
ok 3, $x eq ${thaw freeze \$x};
