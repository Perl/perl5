#!./perl

# $Id: lock.t,v 1.0.1.1 2000/09/28 21:44:06 ram Exp $
#
#  @COPYRIGHT@
#
# $Log: lock.t,v $
# Revision 1.0.1.1  2000/09/28 21:44:06  ram
# patch2: created.
#
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

use Storable qw(lock_store lock_retrieve);

print "1..5\n";

@a = ('first', undef, 3, -4, -3.14159, 456, 4.5);

#
# We're just ensuring things work, we're not validating locking.
#

ok 1, defined lock_store(\@a, 'store');
ok 2, $dumped = &dump(\@a);

$root = lock_retrieve('store');
ok 3, ref $root eq 'ARRAY';
ok 4, @a == @$root;
ok 5, &dump($root) eq $dumped; 

unlink 't/store';

