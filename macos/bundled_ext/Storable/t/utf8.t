#!./perl

# $Id: utf8.t,v 1.0.1.2 2000/09/28 21:44:17 ram Exp $
#
#  @COPYRIGHT@
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
    chdir('t') if -d 't';
    @INC = '.'; 
    push @INC, '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bStorable\b/) {
        print "1..0 # Skip: Storable was not built\n";
        exit 0;
    }
    require 'lib/st-dump.pl';
}

sub ok;

use Storable qw(thaw freeze);

print "1..1\n";

$x = chr(1234);
ok 1, $x eq ${thaw freeze \$x};

