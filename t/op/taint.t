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
my $Is_MSWin32 = $^O eq 'MSWin32';
my $Invoke_Perl = $Is_VMS ? 'MCR Sys$Disk:[]Perl.' :
                  $Is_MSWin32 ? '.\perl' : './perl';
if ($Is_VMS) {
    my ($olddcl) = $ENV{'DCL$PATH'} =~ /^(.*)$/;
    my ($oldifs) = $ENV{IFS} =~ /^(.*)$/;
    eval <<EndOfCleanup;
	END {
	    \$ENV{PATH} = '';
	    warn "# Note: logical name 'PATH' may have been deleted\n";
	    \$ENV{IFS} =  \$oldifs;
	    \$ENV{'DCL\$PATH'} = \$olddcl;
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
my $ECHO = ($Is_MSWin32 ? ".\\echo$$" : "./echo$$");
END { unlink $ECHO }
open PROG, "> $ECHO" or die "Can't create $ECHO: $!";
print PROG 'print "@ARGV\n"', "\n";
close PROG;
my $echo = "$Invoke_Perl $ECHO";

print "1..136\n";

# First, let's make sure that Perl is checking the dangerous
# environment variables. Maybe they aren't set yet, so we'll
# taint them ourselves.
{
    $ENV{'DCL$PATH'} = '' if $Is_VMS;

    if ($Is_MSWin32) {
	print "# PATH/IFS tainting tests skipped\n";
	for (1..4) { print "ok $_\n" }
    }
    else {
	$ENV{PATH} = $TAINT;
	$ENV{IFS} = " \t\n";
	test 1, eval { `$echo 1` } eq '';
	test 2, $@ =~ /^Insecure \$ENV{PATH}/, $@;

	$ENV{PATH} = '';
	$ENV{IFS} = $TAINT;
	test 3, eval { `$echo 1` } eq '';
	test 4, $@ =~ /^Insecure \$ENV{IFS}/, $@;
    }
    my $tmp;
    if ($^O eq 'os2' || $^O eq 'amigaos' || $Is_MSWin32) {
	print "# all directories are writeable\n";
    }
    else {
	$tmp = (grep { defined and -d and (stat _)[2] & 2 }
		     qw(/tmp /var/tmp /usr/tmp /sys$scratch),
		     @ENV{qw(TMP TEMP)})[0]
	    or print "# can't find world-writeable directory to test PATH\n";
    }

    if ($tmp) {
	$ENV{PATH} = $tmp;
	$ENV{IFS} = " \t\n";
	test 5, eval { `$echo 1` } eq '';
	test 6, $@ =~ /^Insecure directory in \$ENV{PATH}/, $@;
    }
    else {
	for (5..6) { print "ok $_\n" }
    }

    $ENV{PATH} = '';
    $ENV{IFS} = " \t\n";
    test 7, eval { `$echo 1` } eq "1\n";
    test 8, $@ eq '', $@;

    if ($Is_VMS) {
	$ENV{'DCL$PATH'} = $TAINT;
	test 9,  eval { `$echo 1` } eq '';
	test 10, $@ =~ /^Insecure \$ENV{DCL\$PATH}/, $@;
	if ($tmp) {
	    $ENV{'DCL$PATH'} = $tmp;
	    test 11, eval { `$echo 1` } eq '';
	    test 12, $@ =~ /^Insecure directory in \$ENV{DCL\$PATH}/, $@;
	}
	else {
	    print "# can't find world-writeable directory to test DCL\$PATH\n";
	    for (11..12) { print "ok $_\n" }
	}
	$ENV{'DCL$PATH'} = '';
    }
    else {
	print "# This is not VMS\n";
	for (9..12) { print "ok $_\n"; }
    }
}

# Let's see that we can taint and untaint as needed.
{
    my $foo = $TAINT;
    test 13, tainted $foo;

    # That was a sanity check. If it failed, stop the insanity!
    die "Taint checks don't seem to be enabled" unless tainted $foo;

    $foo = "foo";
    test 14, not tainted $foo;

    taint_these($foo);
    test 15, tainted $foo;

    my @list = 1..10;
    test 16, not any_tainted @list;
    taint_these @list[1,3,5,7,9];
    test 17, any_tainted @list;
    test 18, all_tainted @list[1,3,5,7,9];
    test 19, not any_tainted @list[0,2,4,6,8];

    ($foo) = $foo =~ /(.+)/;
    test 20, not tainted $foo;

    $foo = $1 if ('bar' . $TAINT) =~ /(.+)/;
    test 21, not tainted $foo;
    test 22, $foo eq 'bar';

    my $pi = 4 * atan2(1,1) + $TAINT0;
    test 23, tainted $pi;

    ($pi) = $pi =~ /(\d+\.\d+)/;
    test 24, not tainted $pi;
    test 25, sprintf("%.5f", $pi) eq '3.14159';
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
    test 26, !$?, "Exited with status $?";
    unlink $arg;
}

# Reading from a file should be tainted
{
    my $file = './TEST';
    test 27, open(FILE, $file), "Couldn't open '$file': $!";

    my $block;
    sysread(FILE, $block, 100);
    my $line = <FILE>;
    close FILE;
    test 28, tainted $block;
    test 29, tainted $line;
}

# Globs should be tainted.
{
    # Some glob implementations need to spawn system programs.
    local $ENV{PATH} = '';
    $ENV{PATH} = (-l '/bin' ? '' : '/bin:') . '/usr/bin' unless $Is_VMS;

    my @globs = <*>;
    test 30, all_tainted @globs;

    @globs = glob '*';
    test 31, all_tainted @globs;
}

# Output of commands should be tainted
{
    my $foo = `$echo abc`;
    test 32, tainted $foo;
}

# Certain system variables should be tainted
{
    test 33, all_tainted $^X, $0;
}

# Results of matching should all be untainted
{
    my $foo = "abcdefghi" . $TAINT;
    test 34, tainted $foo;

    $foo =~ /def/;
    test 35, not any_tainted $`, $&, $';

    $foo =~ /(...)(...)(...)/;
    test 36, not any_tainted $1, $2, $3, $+;

    my @bar = $foo =~ /(...)(...)(...)/;
    test 37, not any_tainted @bar;

    test 38, tainted $foo;	# $foo should still be tainted!
    test 39, $foo eq "abcdefghi";
}

# Operations which affect files can't use tainted data.
{
    test 40, eval { chmod 0, $TAINT } eq '', 'chmod';
    test 41, $@ =~ /^Insecure dependency/, $@;

    # There is no feature test in $Config{} for truncate,
    #   so we allow for the possibility that it's missing.
    test 42, eval { truncate 'NoSuChFiLe', $TAINT0 } eq '', 'truncate';
    test 43, $@ =~ /^(?:Insecure dependency|truncate not implemented)/, $@;

    test 44, eval { rename '', $TAINT } eq '', 'rename';
    test 45, $@ =~ /^Insecure dependency/, $@;

    test 46, eval { unlink $TAINT } eq '', 'unlink';
    test 47, $@ =~ /^Insecure dependency/, $@;

    test 48, eval { utime $TAINT } eq '', 'utime';
    test 49, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_chown}) {
	test 50, eval { chown -1, -1, $TAINT } eq '', 'chown';
	test 51, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# chown() is not available\n";
	for (50..51) { print "ok $_\n" }
    }

    if ($Config{d_link}) {
	test 52, eval { link $TAINT, '' } eq '', 'link';
	test 53, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# link() is not available\n";
	for (52..53) { print "ok $_\n" }
    }

    if ($Config{d_symlink}) {
	test 54, eval { symlink $TAINT, '' } eq '', 'symlink';
	test 55, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# symlink() is not available\n";
	for (54..55) { print "ok $_\n" }
    }
}

# Operations which affect directories can't use tainted data.
{
    test 56, eval { mkdir $TAINT0, $TAINT } eq '', 'mkdir';
    test 57, $@ =~ /^Insecure dependency/, $@;

    test 58, eval { rmdir $TAINT } eq '', 'rmdir';
    test 59, $@ =~ /^Insecure dependency/, $@;

    test 60, eval { chdir $TAINT } eq '', 'chdir';
    test 61, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_chroot}) {
	test 62, eval { chroot $TAINT } eq '', 'chroot';
	test 63, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# chroot() is not available\n";
	for (62..63) { print "ok $_\n" }
    }
}

# Some operations using files can't use tainted data.
{
    my $foo = "imaginary library" . $TAINT;
    test 64, eval { require $foo } eq '', 'require';
    test 65, $@ =~ /^Insecure dependency/, $@;

    my $filename = "./taintB$$";	# NB: $filename isn't tainted!
    END { unlink $filename if defined $filename }
    $foo = $filename . $TAINT;
    unlink $filename;	# in any case

    test 66, eval { open FOO, $foo } eq '', 'open for read';
    test 67, $@ eq '', $@;		# NB: This should be allowed
    test 68, $! == 2;			# File not found

    test 69, eval { open FOO, "> $foo" } eq '', 'open for write';
    test 70, $@ =~ /^Insecure dependency/, $@;
}

# Commands to the system can't use tainted data
{
    my $foo = $TAINT;

    if ($^O eq 'amigaos') {
	print "# open(\"|\") is not available\n";
	for (71..74) { print "ok $_\n" }
    }
    else {
	test 71, eval { open FOO, "| $foo" } eq '', 'popen to';
	test 72, $@ =~ /^Insecure dependency/, $@;

	test 73, eval { open FOO, "$foo |" } eq '', 'popen from';
	test 74, $@ =~ /^Insecure dependency/, $@;
    }

    test 75, eval { exec $TAINT } eq '', 'exec';
    test 76, $@ =~ /^Insecure dependency/, $@;

    test 77, eval { system $TAINT } eq '', 'system';
    test 78, $@ =~ /^Insecure dependency/, $@;

    $foo = "*";
    taint_these $foo;

    test 79, eval { `$echo 1$foo` } eq '', 'backticks';
    test 80, $@ =~ /^Insecure dependency/, $@;

    if ($Is_VMS) { # wildcard expansion doesn't invoke shell, so is safe
	test 81, join('', eval { glob $foo } ) ne '', 'globbing';
	test 82, $@ eq '', $@;
    }
    else {
	test 81, join('', eval { glob $foo } ) eq '', 'globbing';
	test 82, $@ =~ /^Insecure dependency/, $@;
    }
}

# Operations which affect processes can't use tainted data.
{
    test 83, eval { kill 0, $TAINT } eq '', 'kill';
    test 84, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_setpgrp}) {
	test 85, eval { setpgrp 0, $TAINT } eq '', 'setpgrp';
	test 86, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# setpgrp() is not available\n";
	for (85..86) { print "ok $_\n" }
    }

    if ($Config{d_setprior}) {
	test 87, eval { setpriority 0, $TAINT, $TAINT } eq '', 'setpriority';
	test 88, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# setpriority() is not available\n";
	for (87..88) { print "ok $_\n" }
    }
}

# Some miscellaneous operations can't use tainted data.
{
    if ($Config{d_syscall}) {
	test 89, eval { syscall $TAINT } eq '', 'syscall';
	test 90, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# syscall() is not available\n";
	for (89..90) { print "ok $_\n" }
    }

    {
	my $foo = "x" x 979;
	taint_these $foo;
	local *FOO;
	my $temp = "./taintC$$";
	END { unlink $temp }
	test 91, open(FOO, "> $temp"), "Couldn't open $temp for write: $!";

	test 92, eval { ioctl FOO, $TAINT, $foo } eq '', 'ioctl';
	test 93, $@ =~ /^Insecure dependency/, $@;

	if ($Config{d_fcntl}) {
	    test 94, eval { fcntl FOO, $TAINT, $foo } eq '', 'fcntl';
	    test 95, $@ =~ /^Insecure dependency/, $@;
	}
	else {
	    print "# fcntl() is not available\n";
	    for (94..95) { print "ok $_\n" }
	}

	close FOO;
    }
}

# Some tests involving references
{
    my $foo = 'abc' . $TAINT;
    my $fooref = \$foo;
    test 96, not tainted $fooref;
    test 97, tainted $$fooref;
    test 98, tainted $foo;
}

# Some tests involving assignment
{
    my $foo = $TAINT0;
    my $bar = $foo;
    test 99, all_tainted $foo, $bar;
    test 100, tainted($foo = $bar);
    test 101, tainted($bar = $bar);
    test 102, tainted($bar += $bar);
    test 103, tainted($bar -= $bar);
    test 104, tainted($bar *= $bar);
    test 105, tainted($bar++);
    test 106, tainted($bar /= $bar);
    test 107, tainted($bar += 0);
    test 108, tainted($bar -= 2);
    test 109, tainted($bar *= -1);
    test 110, tainted($bar /= 1);
    test 111, tainted($bar--);
    test 112, $bar == 0;
}

# Test assignment and return of lists
{
    my @foo = ("A", "tainted" . $TAINT, "B");
    test 113, not tainted $foo[0];
    test 114,     tainted $foo[1];
    test 115, not tainted $foo[2];
    my @bar = @foo;
    test 116, not tainted $bar[0];
    test 117,     tainted $bar[1];
    test 118, not tainted $bar[2];
    my @baz = eval { "A", "tainted" . $TAINT, "B" };
    test 119, not tainted $baz[0];
    test 120,     tainted $baz[1];
    test 121, not tainted $baz[2];
    my @plugh = eval q[ "A", "tainted" . $TAINT, "B" ];
    test 122, not tainted $plugh[0];
    test 123,     tainted $plugh[1];
    test 124, not tainted $plugh[2];
    my $nautilus = sub { "A", "tainted" . $TAINT, "B" };
    test 125, not tainted ((&$nautilus)[0]);
    test 126,     tainted ((&$nautilus)[1]);
    test 127, not tainted ((&$nautilus)[2]);
    my @xyzzy = &$nautilus;
    test 128, not tainted $xyzzy[0];
    test 129,     tainted $xyzzy[1];
    test 130, not tainted $xyzzy[2];
    my $red_october = sub { return "A", "tainted" . $TAINT, "B" };
    test 131, not tainted ((&$red_october)[0]);
    test 132,     tainted ((&$red_october)[1]);
    test 133, not tainted ((&$red_october)[2]);
    my @corge = &$red_october;
    test 134, not tainted $corge[0];
    test 135,     tainted $corge[1];
    test 136, not tainted $corge[2];
}
