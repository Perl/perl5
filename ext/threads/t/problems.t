
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    unless ($Config{'useithreads'}) {
	print "1..0 # Skip: no useithreads\n";
 	exit 0;	
    }
}

use ExtUtils::testlib;
use strict;
use threads;
use threads::shared;
use Test::More tests => 4;


#
# This tests for too much destruction
# which was caused by cloning stashes
# on join which led to double the dataspace
#
#########################

$|++;
use Devel::Peek;


{ 

    sub Foo::DESTROY { 
	my $self = shift;
	my ($package, $file, $line) = caller;
	is(threads->tid(),$self->{tid}, "In destroy it should be correct too" )
    }
    my $foo;
    $foo = bless {tid => 0}, 'Foo';			  
    my $bar = threads->create(sub { 
	is(threads->tid(),1, "And tid be 10 here");
	$foo->{tid} = 1;
	return $foo;
    })->join();
    $bar->{tid} = 0;


}
1;







