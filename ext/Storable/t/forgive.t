#!./perl

# $Id: forgive.t,v 1.0.1.1 2000/09/01 19:40:42 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the same terms as Perl 5, as specified
#  in the README file that comes with the distribution.
#
# Original Author: Ulrich Pfeifer
# (C) Copyright 1997, Universitat Dortmund, all rights reserved.
#
# $Log: forgive.t,v $
# Revision 1.0.1.1  2000/09/01 19:40:42  ram
# Baseline for first official release.
#
# Revision 1.0  2000/09/01 19:40:41  ram
# Baseline for first official release.
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
}

use Storable qw(store retrieve);
use File::Spec;

print "1..8\n";

my $test = 1;
my $bad = ['foo', sub { 1 },  'bar'];
my $result;

eval {$result = store ($bad , 'store')};
print ((!defined $result)?"ok $test\n":"not ok $test\n"); $test++;
print (($@ ne '')?"ok $test\n":"not ok $test\n"); $test++;

$Storable::forgive_me=1;

my $devnull = File::Spec->devnull;

open(SAVEERR, ">&STDERR");
open(STDERR, ">$devnull") or 
  ( print SAVEERR "Unable to redirect STDERR: $!\n" and exit(1) );

eval {$result = store ($bad , 'store')};

open(STDERR, ">&SAVEERR");

print ((defined $result)?"ok $test\n":"not ok $test\n"); $test++;
print (($@ eq '')?"ok $test\n":"not ok $test\n"); $test++;

my $ret = retrieve('store');
print ((defined $ret)?"ok $test\n":"not ok $test\n"); $test++;
print (($ret->[0] eq 'foo')?"ok $test\n":"not ok $test\n"); $test++;
print (($ret->[2] eq 'bar')?"ok $test\n":"not ok $test\n"); $test++;
print ((ref $ret->[1] eq 'SCALAR')?"ok $test\n":"not ok $test\n"); $test++;


END { 1 while unlink 'store' }
