#!./perl

# $Id: tied_items.t,v 0.7.1.2 2000/08/14 07:20:35 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# $Log: tied_items.t,v $
# Revision 0.7.1.2  2000/08/14 07:20:35  ram
# patch2: removed spurious dependency to Devel::Peek, used for testing only
#
# Revision 0.7.1.1  2000/08/13 20:10:31  ram
# patch1: created
#

#
# Tests ref to items in tied hash/array structures.
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
$^W = 0;

print "1..8\n";

use Storable qw(dclone);

$h_fetches = 0;

sub H::TIEHASH { bless \(my $x), "H" }
sub H::FETCH { $h_fetches++; $_[1] - 70 }

tie %h, "H";

$ref = \$h{77};
$ref2 = dclone $ref;

ok 1, $h_fetches == 0;
ok 2, $$ref2 eq $$ref;
ok 3, $$ref2 == 7;
ok 4, $h_fetches == 2;

$a_fetches = 0;

sub A::TIEARRAY { bless \(my $x), "A" }
sub A::FETCH { $a_fetches++; $_[1] - 70 }

tie @a, "A";

$ref = \$a[78];
$ref2 = dclone $ref;

ok 5, $a_fetches == 0;
ok 6, $$ref2 eq $$ref;
ok 7, $$ref2 == 8;
# I don't understand why it's 3 and not 2
ok 8, $a_fetches == 3;

