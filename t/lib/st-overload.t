#!./perl

# $Id: overload.t,v 0.7.1.1 2000/08/13 20:10:10 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  
# $Log: overload.t,v $
# Revision 0.7.1.1  2000/08/13 20:10:10  ram
# patch1: created
#

sub BEGIN {
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

use Storable qw(freeze thaw);

print "1..7\n";

package OVERLOADED;

use overload
	'""' => sub { $_[0][0] };

package main;

$a = bless [77], OVERLOADED;

$b = thaw freeze $a;
ok 1, ref $b eq 'OVERLOADED';
ok 2, "$b" eq "77";

$c = thaw freeze \$a;
ok 3, ref $c eq 'REF';
ok 4, ref $$c eq 'OVERLOADED';
ok 5, "$$c" eq "77";

$d = thaw freeze [$a, $a];
ok 6, "$d->[0]" eq "77";
$d->[0][0]++;
ok 7, "$d->[1]" eq "78";

