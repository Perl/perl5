#!./perl -T
#
# Taint tests by Tom Phoenix <rootbeer@teleport.com>.
#
# I don't claim to know all about tainting. If anyone sees
# tests that I've missed here, please add them. But this is 
# better than having no tests at all, right?
#

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib' if -d '../lib';
}

use strict;
use Config;

my $Is_VMS = $^O eq 'VMS';
my $Invoke_Perl = $Is_VMS ? 'MCR Sys$Disk:[]Perl.' : './perl';
if ($Is_VMS) {
    eval <<EndOfCleanup;
	END {
	    \$ENV{PATH} = '';
	    warn "# Note: logical name 'PATH' may have been deleted\n";
	    \$ENV{IFS} =  "$ENV{IFS}";
	    \$ENV{'DCL\$PATH'} = "$ENV{'DCL$PATH'}";
	}
EndOfCleanup
}

# Sources of taint:
#   The empty tainted value, for tainting strings
my $TAINT = substr($^X, 0, 0);
#   A tainted zero, useful for tainting numbers
my $TAINT0 = 0 + $TAINT;

# This taints each argument passed. All must be lvalues.
# Side effect: It also stringifies them. :-(
sub taint_these (@) {
    for (@_) { $_ .= $TAINT }
}

# How to identify taint when you see it
sub any_tainted (@) {
    not eval { join("",@_), kill 0; 1 };
}
sub tainted ($) {
    any_tainted @_;
}
sub all_tainted (@) {
    for (@_) { return 0 unless tainted $_ }
    1;
}

sub test ($$;$) {
    my($serial, $boolean, $diag) = @_;
    if ($boolean) {
	print "ok $serial\n";
    } else {
	print "not ok $serial\n";
	for (split m/^/m, $diag) {
	    print "# $_";
	}
	print "\n" unless 
	    $diag eq ''
	    or substr($diag, -1) eq "\n";
    }
}

# We need an external program to call.
my $ECHO = "./echo$$";
END { unlink $ECHO }
open PROG, "> $ECHO" or die "Can't create $ECHO: $!";
print PROG 'print "@ARGV\n"', "\n";
close PROG;
my $echo = "$Invoke_Perl $ECHO";

print "1..96\n";

# First, let's make sure that Perl is checking the dangerous
# environment variables. Maybe they aren't set yet, so we'll
# taint them ourselves.
{
    $ENV{'DCL$PATH'} = '' if $Is_VMS;

    $ENV{PATH} = $TAINT;
    $ENV{IFS} = '';
    test 1, eval { `$echo 1` } eq '';
    test 2, $@ =~ /^Insecure \$ENV{PATH}/, $@;

    $ENV{PATH} = '';
    $ENV{IFS} = $TAINT;
    test 3, eval { `$echo 1` } eq '';
    test 4, $@ =~ /^Insecure \$ENV{IFS}/, $@;

    my ($tmp) = grep { (stat)[2] & 2 } '/tmp', '/var/tmp', '/usr/tmp';
    if ($tmp) {
	$ENV{PATH} = $tmp;
	test 5, eval { `$echo 1` } eq '';
	test 6, $@ =~ /^Insecure directory in \$ENV{PATH}/, $@;
    }
    else {
	print "# can't find writeable directory to test PATH tainting\n";
	for (5..6) { print "ok $_\n" }
    }

    $ENV{PATH} = '';
    $ENV{IFS} = '';
    test 7, eval { `$echo 1` } eq "1\n";
    test 8, $@ eq '', $@;

    if ($Is_VMS) {
	$ENV{'DCL$PATH'} = $TAINT;
	test 9,  eval { `$echo 1` } eq '';
	test 10, $@ =~ /^Insecure \$ENV{DCL\$PATH}/, $@;
	$ENV{'DCL$PATH'} = '';
    }
    else {
	print "# This is not VMS\n";
	for (9..10) { print "ok $_\n"; }
    }
}

# Let's see that we can taint and untaint as needed.
{
    my $foo = $TAINT;
    test 11, tainted $foo;

    $foo = "foo";
    test 12, not tainted $foo;

    taint_these($foo);
    test 13, tainted $foo;

    my @list = 1..10;
    test 14, not any_tainted @list;
    taint_these @list[1,3,5,7,9];
    test 15, any_tainted @list;
    test 16, all_tainted @list[1,3,5,7,9];
    test 17, not any_tainted @list[0,2,4,6,8];

    ($foo) = $foo =~ /(.+)/;
    test 18, not tainted $foo;

    $foo = $1 if ('bar' . $TAINT) =~ /(.+)/;
    test 19, not tainted $foo;
    test 20, $foo eq 'bar';

    my $pi = 4 * atan2(1,1) + $TAINT0;
    test 21, tainted $pi;

    ($pi) = $pi =~ /(\d+\.\d+)/;
    test 22, not tainted $pi;
    test 23, sprintf("%.5f", $pi) eq '3.14159';
}

# How about command-line arguments? The problem is that we don't
# always get some, so we'll run another process with some.
{
    my $arg = "./arg$$";
    open PROG, "> $arg" or die "Can't create $arg: $!";
    print PROG q{
	eval { join('', @ARGV), kill 0 };
	exit 0 if $@ =~ /^Insecure dependency/;
	print "# Oops: \$@ was [$@]\n";
	exit 1;
    };
    close PROG;
    print `$Invoke_Perl "-T" $arg and some suspect arguments`;
    test 24, !$?, "Exited with status $?";
    unlink $arg;
}

# Reading from a file should be tainted
{
    my $file = './perl' . $Config{exe_ext};
    test 25, open(FILE, $file), "Couldn't open '$file': $!";

    my $block;
    sysread(FILE, $block, 100);
    my $line = <FILE>;		# Should "work"
    close FILE;
    test 26, tainted $block;
    test 27, tainted $line;
}

# Globs should be tainted. 
{
    my @globs = <*>;
    test 28, all_tainted @globs;

    @globs = glob '*';
    test 29, all_tainted @globs;
}

# Output of commands should be tainted
{
    my $foo = `$echo abc`;
    test 30, tainted $foo;
}

# Certain system variables should be tainted
{
    test 31, all_tainted $^X, $0;
}

# Results of matching should all be untainted
{
    my $foo = "abcdefghi" . $TAINT;
    test 32, tainted $foo;

    $foo =~ /def/;
    test 33, not any_tainted $`, $&, $';

    $foo =~ /(...)(...)(...)/;
    test 34, not any_tainted $1, $2, $3, $+;

    my @bar = $foo =~ /(...)(...)(...)/;
    test 35, not any_tainted @bar;

    test 36, tainted $foo;	# $foo should still be tainted!
    test 37, $foo eq "abcdefghi";
}

# Operations which affect files can't use tainted data.
{
    test 38, eval { chmod 0, $TAINT } eq '', 'chmod';
    test 39, $@ =~ /^Insecure dependency/, $@;

    test 40, eval { truncate 'NoSuChFiLe', $TAINT0 } eq '', 'truncate';
    test 41, $@ =~ /^Insecure dependency/, $@;

    test 42, eval { rename '', $TAINT } eq '', 'rename';
    test 43, $@ =~ /^Insecure dependency/, $@;

    test 44, eval { unlink $TAINT } eq '', 'unlink';
    test 45, $@ =~ /^Insecure dependency/, $@;

    test 46, eval { utime $TAINT } eq '', 'utime';
    test 47, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_chown}) {
	test 48, eval { chown -1, -1, $TAINT } eq '', 'chown';
	test 49, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# chown() is not available\n";
	for (48..49) { print "ok $_\n" }
    }

    if ($Config{d_link}) {
	test 50, eval { link $TAINT, '' } eq '', 'link';
	test 51, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# link() is not available\n";
	for (50..51) { print "ok $_\n" }
    }

    if ($Config{d_symlink}) {
	test 52, eval { symlink $TAINT, '' } eq '', 'symlink';
	test 53, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# symlink() is not available\n";
	for (52..53) { print "ok $_\n" }
    }
}

# Operations which affect directories can't use tainted data.
{
    test 54, eval { mkdir $TAINT0, $TAINT } eq '', 'mkdir';
    test 55, $@ =~ /^Insecure dependency/, $@;

    test 56, eval { rmdir $TAINT } eq '', 'rmdir';
    test 57, $@ =~ /^Insecure dependency/, $@;

    test 58, eval { chdir $TAINT } eq '', 'chdir';
    test 59, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_chroot}) {
	test 60, eval { chroot $TAINT } eq '', 'chroot';
	test 61, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# chroot() is not available\n";
	for (60..61) { print "ok $_\n" }
    }
}

# Some operations using files can't use tainted data.
{
    my $foo = "imaginary library" . $TAINT;
    test 62, eval { require $foo } eq '', 'require';
    test 63, $@ =~ /^Insecure dependency/, $@;

    my $filename = "./taintB$$";	# NB: $filename isn't tainted!
    END { unlink $filename if defined $filename }
    $foo = $filename . $TAINT;
    unlink $filename;	# in any case

    test 64, eval { open FOO, $foo } eq '', 'open for read';
    test 65, $@ eq '', $@;		# NB: This should be allowed
    test 66, $! == 2;			# File not found

    test 67, eval { open FOO, "> $foo" } eq '', 'open for write';
    test 68, $@ =~ /^Insecure dependency/, $@;
}

# Commands to the system can't use tainted data
{
    my $foo = $TAINT;

    if ($^O eq 'amigaos') {
	print "# open(\"|\") is not available\n";
	for (69..72) { print "ok $_\n" }
    }
    else {
	test 69, eval { open FOO, "| $foo" } eq '', 'popen to';
	test 70, $@ =~ /^Insecure dependency/, $@;

	test 71, eval { open FOO, "$foo |" } eq '', 'popen from';
	test 72, $@ =~ /^Insecure dependency/, $@;
    }

    test 73, eval { exec $TAINT } eq '', 'exec';
    test 74, $@ =~ /^Insecure dependency/, $@;

    test 75, eval { system $TAINT } eq '', 'system';
    test 76, $@ =~ /^Insecure dependency/, $@;

    $foo = "*";
    taint_these $foo;

    test 77, eval { `$echo 1$foo` } eq '', 'backticks';
    test 78, $@ =~ /^Insecure dependency/, $@;

    if ($Is_VMS) { # wildcard expansion doesn't invoke shell, so is safe
	test 79, join('', eval { glob $foo } ) ne '', 'globbing';
	test 80, $@ eq '', $@;
    }
    else {
	test 79, join('', eval { glob $foo } ) eq '', 'globbing';
	test 80, $@ =~ /^Insecure dependency/, $@;
    }
}

# Operations which affect processes can't use tainted data.
{
    test 81, eval { kill 0, $TAINT } eq '', 'kill';
    test 82, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_setpgrp}) {
	test 83, eval { setpgrp 0, $TAINT } eq '', 'setpgrp';
	test 84, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# setpgrp() is not available\n";
	for (83..84) { print "ok $_\n" }
    }

    if ($Config{d_setprior}) {
	test 85, eval { setpriority 0, $TAINT, $TAINT } eq '', 'setpriority';
	test 86, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# setpriority() is not available\n";
	for (85..86) { print "ok $_\n" }
    }
}

# Some miscellaneous operations can't use tainted data.
{
    if ($Config{d_syscall}) {
	test 87, eval { syscall $TAINT } eq '', 'syscall';
	test 88, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# syscall() is not available\n";
	for (87..88) { print "ok $_\n" }
    }

    {
	my $foo = "x" x 979;
	taint_these $foo;
	local *FOO;
	my $temp = "./taintC$$";
	END { unlink $temp }
	test 89, open(FOO, "> $temp"), "Couldn't open $temp for write: $!";

	test 90, eval { ioctl FOO, $TAINT, $foo } eq '', 'ioctl';
	test 91, $@ =~ /^Insecure dependency/, $@;

	if ($Config{d_fcntl}) {
	    test 92, eval { fcntl FOO, $TAINT, $foo } eq '', 'fcntl';
	    test 93, $@ =~ /^Insecure dependency/, $@;
	}
	else {
	    print "# fcntl() is not available\n";
	    for (92..93) { print "ok $_\n" }
	}

	close FOO;
    }
}

# Some tests involving references 
{
    my $foo = 'abc' . $TAINT;
    my $fooref = \$foo;
    test 94, not tainted $fooref;
    test 95, tainted $$fooref;
    test 96, tainted $foo;
}
