#!./perl

#
# Verify that C<die> return the return code
#	-- Robin Barker 
#

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

skip_all('broken on MPE/iX') if $^O eq 'mpeix';

$| = 1;


my %tests = (
	 1 => [   0,   0],
	 2 => [   0,   1], 
	 3 => [   0, 127], 
	 4 => [   0, 128], 
	 5 => [   0, 255], 
	 6 => [   0, 256], 
	 7 => [   0, 512], 
	 8 => [   1,   0],
	 9 => [   1,   1],
	10 => [   1, 256],
	11 => [ 128,   0],
	12 => [ 128,   1],
	13 => [ 128, 256],
	14 => [ 255,   0],
	15 => [ 255,   1],
	16 => [ 255, 256],
	# see if implicit close preserves $?
	17 => [  0,  512, '{ local *F; open F, q[TEST]; close F; $!=0 } die;'],
);

my $max = keys %tests;

my $vms_exit_mode = 0;

if ($^O eq 'VMS') {
    if (eval 'require VMS::Feature') {
        $vms_exit_mode = !(VMS::Feature::current("posix_exit"));
    } else {
        my $env_unix_rpt = $ENV{'DECC$FILENAME_UNIX_REPORT'} || '';
        my $env_posix_ex = $ENV{'PERL_VMS_POSIX_EXIT'} || '';
        my $unix_rpt = $env_unix_rpt =~ /^[ET1]/i; 
        my $posix_ex = $env_posix_ex =~ /^[ET1]/i;
        if (($unix_rpt || $posix_ex) ) {
            $vms_exit_mode = 0;
        } else {
            $vms_exit_mode = 1;
        }
    }
}

plan(tests => $max);

# Dump any error messages from the dying processes off to a temp file.
my $tempfile = tempfile();
open STDERR, '>', $tempfile or die "Can't open temp error file $tempfile:  $!";

foreach my $test (1 .. $max) {
    my($bang, $query, $code) = @{$tests{$test}};
    $code ||= 'die;';
    if ($^O eq 'MSWin32' || $^O eq 'NetWare' || $^O eq 'VMS') {
        system(qq{$^X -e "\$! = $bang; \$? = $query; $code"});
    }
    else {
        system(qq{$^X -e '\$! = $bang; \$? = $query; $code'});
    }
    my $exit = $?;

    # The legacy VMS exit code 44 (SS$_ABORT) is returned if a program dies.
    # We only get the severity bits, which boils down to 4.  See L<perlvms/$?>.
    $bang = 4 if $vms_exit_mode;

    is($exit, (($bang || ($query >> 8) || 255) << 8),
       sprintf "exit = 0x%04x bang = 0x%04x query = 0x%04x", $exit, $bang, $query);
}

close STDERR;

