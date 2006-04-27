#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
}

require 'test.pl';
plan( tests => 16 );

use strict;
use warnings;

use vars qw{ @warnings };

BEGIN {
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $| = 1;
}

my $fail_odd      = 'Odd number of elements in hash assignment at ';
my $fail_odd_anon = 'Odd number of elements in anonymous hash at ';
my $fail_ref      = 'Reference found where even-sized list expected at ';
my $fail_not_hr   = 'Not a HASH reference at ';

{
    @warnings = ();
    my %hash = (1..3);
    cmp_ok(scalar(@warnings),'==',1,'odd count');
    cmp_ok(substr($warnings[0],0,length($fail_odd)),'eq',$fail_odd,'odd msg');

    @warnings = ();
    %hash = 1;
    cmp_ok(scalar(@warnings),'==',1,'scalar count');
    cmp_ok(substr($warnings[0],0,length($fail_odd)),'eq',$fail_odd,'scalar msg');

    @warnings = ();
    %hash = { 1..3 };
    cmp_ok(scalar(@warnings),'==',2,'odd hashref count');
    cmp_ok(substr($warnings[0],0,length($fail_odd_anon)),'eq',$fail_odd_anon,'odd hashref msg 1');
    cmp_ok(substr($warnings[1],0,length($fail_ref)),'eq',$fail_ref,'odd hashref msg 2');

    @warnings = ();
    %hash = [ 1..3 ];
    cmp_ok(scalar(@warnings),'==',1,'arrayref count');
    cmp_ok(substr($warnings[0],0,length($fail_ref)),'eq',$fail_ref,'arrayref msg');

    @warnings = ();
    %hash = sub { print "fenice" };
    cmp_ok(scalar(@warnings),'==',1,'coderef count');
    cmp_ok(substr($warnings[0],0,length($fail_odd)),'eq',$fail_odd,'coderef msg');

    @warnings = ();
    $_ = { 1..10 };
    cmp_ok(scalar(@warnings),'==',0,'hashref assign');

    {
	# "Pseudo-hashes are deprecated" warnings tested in warnings/av
	no warnings 'deprecated';

	@warnings = ();
	my $avhv = [{x=>1,y=>2}];
	%$avhv = (x=>13,'y');
	cmp_ok(scalar(@warnings),'==',1,'odd pseudohash count');
	cmp_ok(substr($warnings[0],0,length($fail_odd)),'eq',$fail_odd,'odd pseudohash msg');

	@warnings = ();
	%$avhv = 'x';
	cmp_ok(scalar(@warnings),'==',1,'scalar pseudohash count');
	cmp_ok(substr($warnings[0],0,length($fail_odd)),'eq',$fail_odd,'scalar pseudohash msg');
    }
}
