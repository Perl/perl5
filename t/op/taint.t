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
my @MoreEnv = qw/IFS ENV CDPATH TERM/;

if ($Is_VMS) {
    my (%old, $x);
    for $x ('DCL$PATH', @MoreEnv) {
	($old{$x}) = $ENV{$x} =~ /^(.*)$/ if exists $ENV{$x};
    }
    eval <<EndOfCleanup;
	END {
	    \$ENV{PATH} = '';
	    warn "# Note: logical name 'PATH' may have been deleted\n";
	    @ENV{keys %old} = values %old;
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

print "1..132\n";

# First, let's make sure that Perl is checking the dangerous
# environment variables. Maybe they aren't set yet, so we'll
# taint them ourselves.
{
    $ENV{'DCL$PATH'} = '' if $Is_VMS;

    $ENV{PATH} = '';
    delete $ENV{IFS};
    delete $ENV{ENV};
    delete $ENV{CDPATH};
    $ENV{TERM} = 'dumb';

    test 1, eval { `$echo 1` } eq "1\n";

    if ($Is_MSWin32) {
	print "# Environment tainting tests skipped\n";
	for (2) { print "ok $_\n" }
    }
    else {
	my @vars = ('PATH', @MoreEnv);
	while (my $v = $vars[0]) {
	    local $ENV{$v} = $TAINT;
	    last if eval { `$echo 1` };
	    last unless $@ =~ /^Insecure \$ENV{$v}/;
	    shift @vars;
	}
	test 2, !@vars, "\$$vars[0]";
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
	local $ENV{PATH} = $tmp;
	test 3, eval { `$echo 1` } eq '';
	test 4, $@ =~ /^Insecure directory in \$ENV{PATH}/, $@;
    }
    else {
	for (3..4) { print "ok $_\n" }
    }

    if ($Is_VMS) {
	$ENV{'DCL$PATH'} = $TAINT;
	test 5,  eval { `$echo 1` } eq '';
	test 6, $@ =~ /^Insecure \$ENV{DCL\$PATH}/, $@;
	if ($tmp) {
	    $ENV{'DCL$PATH'} = $tmp;
	    test 7, eval { `$echo 1` } eq '';
	    test 8, $@ =~ /^Insecure directory in \$ENV{DCL\$PATH}/, $@;
	}
	else {
	    print "# can't find world-writeable directory to test DCL\$PATH\n";
	    for (7..8) { print "ok $_\n" }
	}
	$ENV{'DCL$PATH'} = '';
    }
    else {
	print "# This is not VMS\n";
	for (5..8) { print "ok $_\n"; }
    }
}

# Let's see that we can taint and untaint as needed.
{
    my $foo = $TAINT;
    test 9, tainted $foo;

    # That was a sanity check. If it failed, stop the insanity!
    die "Taint checks don't seem to be enabled" unless tainted $foo;

    $foo = "foo";
    test 10, not tainted $foo;

    taint_these($foo);
    test 11, tainted $foo;

    my @list = 1..10;
    test 12, not any_tainted @list;
    taint_these @list[1,3,5,7,9];
    test 13, any_tainted @list;
    test 14, all_tainted @list[1,3,5,7,9];
    test 15, not any_tainted @list[0,2,4,6,8];

    ($foo) = $foo =~ /(.+)/;
    test 16, not tainted $foo;

    $foo = $1 if ('bar' . $TAINT) =~ /(.+)/;
    test 17, not tainted $foo;
    test 18, $foo eq 'bar';

    my $pi = 4 * atan2(1,1) + $TAINT0;
    test 19, tainted $pi;

    ($pi) = $pi =~ /(\d+\.\d+)/;
    test 20, not tainted $pi;
    test 21, sprintf("%.5f", $pi) eq '3.14159';
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
    test 22, !$?, "Exited with status $?";
    unlink $arg;
}

# Reading from a file should be tainted
{
    my $file = './TEST';
    test 23, open(FILE, $file), "Couldn't open '$file': $!";

    my $block;
    sysread(FILE, $block, 100);
    my $line = <FILE>;
    close FILE;
    test 24, tainted $block;
    test 25, tainted $line;
}

# Globs should be forbidden.
{
    # Some glob implementations need to spawn system programs.
    local $ENV{PATH} = '';
    $ENV{PATH} = (-l '/bin' ? '' : '/bin:') . '/usr/bin' unless $Is_VMS;

    my @globs = eval { <*> };
    test 26, @globs == 0 && $@ =~ /^Insecure dependency/;

    @globs = eval { glob '*' };
    test 27, @globs == 0 && $@ =~ /^Insecure dependency/;
}

# Output of commands should be tainted
{
    my $foo = `$echo abc`;
    test 28, tainted $foo;
}

# Certain system variables should be tainted
{
    test 29, all_tainted $^X, $0;
}

# Results of matching should all be untainted
{
    my $foo = "abcdefghi" . $TAINT;
    test 30, tainted $foo;

    $foo =~ /def/;
    test 31, not any_tainted $`, $&, $';

    $foo =~ /(...)(...)(...)/;
    test 32, not any_tainted $1, $2, $3, $+;

    my @bar = $foo =~ /(...)(...)(...)/;
    test 33, not any_tainted @bar;

    test 34, tainted $foo;	# $foo should still be tainted!
    test 35, $foo eq "abcdefghi";
}

# Operations which affect files can't use tainted data.
{
    test 36, eval { chmod 0, $TAINT } eq '', 'chmod';
    test 37, $@ =~ /^Insecure dependency/, $@;

    # There is no feature test in $Config{} for truncate,
    #   so we allow for the possibility that it's missing.
    test 38, eval { truncate 'NoSuChFiLe', $TAINT0 } eq '', 'truncate';
    test 39, $@ =~ /^(?:Insecure dependency|truncate not implemented)/, $@;

    test 40, eval { rename '', $TAINT } eq '', 'rename';
    test 41, $@ =~ /^Insecure dependency/, $@;

    test 42, eval { unlink $TAINT } eq '', 'unlink';
    test 43, $@ =~ /^Insecure dependency/, $@;

    test 44, eval { utime $TAINT } eq '', 'utime';
    test 45, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_chown}) {
	test 46, eval { chown -1, -1, $TAINT } eq '', 'chown';
	test 47, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# chown() is not available\n";
	for (46..47) { print "ok $_\n" }
    }

    if ($Config{d_link}) {
	test 48, eval { link $TAINT, '' } eq '', 'link';
	test 49, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# link() is not available\n";
	for (48..49) { print "ok $_\n" }
    }

    if ($Config{d_symlink}) {
	test 50, eval { symlink $TAINT, '' } eq '', 'symlink';
	test 51, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# symlink() is not available\n";
	for (50..51) { print "ok $_\n" }
    }
}

# Operations which affect directories can't use tainted data.
{
    test 52, eval { mkdir $TAINT0, $TAINT } eq '', 'mkdir';
    test 53, $@ =~ /^Insecure dependency/, $@;

    test 54, eval { rmdir $TAINT } eq '', 'rmdir';
    test 55, $@ =~ /^Insecure dependency/, $@;

    test 56, eval { chdir $TAINT } eq '', 'chdir';
    test 57, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_chroot}) {
	test 58, eval { chroot $TAINT } eq '', 'chroot';
	test 59, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# chroot() is not available\n";
	for (58..59) { print "ok $_\n" }
    }
}

# Some operations using files can't use tainted data.
{
    my $foo = "imaginary library" . $TAINT;
    test 60, eval { require $foo } eq '', 'require';
    test 61, $@ =~ /^Insecure dependency/, $@;

    my $filename = "./taintB$$";	# NB: $filename isn't tainted!
    END { unlink $filename if defined $filename }
    $foo = $filename . $TAINT;
    unlink $filename;	# in any case

    test 62, eval { open FOO, $foo } eq '', 'open for read';
    test 63, $@ eq '', $@;		# NB: This should be allowed
    test 64, $! == 2;			# File not found

    test 65, eval { open FOO, "> $foo" } eq '', 'open for write';
    test 66, $@ =~ /^Insecure dependency/, $@;
}

# Commands to the system can't use tainted data
{
    my $foo = $TAINT;

    if ($^O eq 'amigaos') {
	print "# open(\"|\") is not available\n";
	for (67..70) { print "ok $_\n" }
    }
    else {
	test 67, eval { open FOO, "| $foo" } eq '', 'popen to';
	test 68, $@ =~ /^Insecure dependency/, $@;

	test 69, eval { open FOO, "$foo |" } eq '', 'popen from';
	test 70, $@ =~ /^Insecure dependency/, $@;
    }

    test 71, eval { exec $TAINT } eq '', 'exec';
    test 72, $@ =~ /^Insecure dependency/, $@;

    test 73, eval { system $TAINT } eq '', 'system';
    test 74, $@ =~ /^Insecure dependency/, $@;

    $foo = "*";
    taint_these $foo;

    test 75, eval { `$echo 1$foo` } eq '', 'backticks';
    test 76, $@ =~ /^Insecure dependency/, $@;

    if ($Is_VMS) { # wildcard expansion doesn't invoke shell, so is safe
	test 77, join('', eval { glob $foo } ) ne '', 'globbing';
	test 78, $@ eq '', $@;
    }
    else {
	test 77, join('', eval { glob $foo } ) eq '', 'globbing';
	test 78, $@ =~ /^Insecure dependency/, $@;
    }
}

# Operations which affect processes can't use tainted data.
{
    test 79, eval { kill 0, $TAINT } eq '', 'kill';
    test 80, $@ =~ /^Insecure dependency/, $@;

    if ($Config{d_setpgrp}) {
	test 81, eval { setpgrp 0, $TAINT } eq '', 'setpgrp';
	test 82, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# setpgrp() is not available\n";
	for (81..82) { print "ok $_\n" }
    }

    if ($Config{d_setprior}) {
	test 83, eval { setpriority 0, $TAINT, $TAINT } eq '', 'setpriority';
	test 84, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# setpriority() is not available\n";
	for (83..84) { print "ok $_\n" }
    }
}

# Some miscellaneous operations can't use tainted data.
{
    if ($Config{d_syscall}) {
	test 85, eval { syscall $TAINT } eq '', 'syscall';
	test 86, $@ =~ /^Insecure dependency/, $@;
    }
    else {
	print "# syscall() is not available\n";
	for (85..86) { print "ok $_\n" }
    }

    {
	my $foo = "x" x 979;
	taint_these $foo;
	local *FOO;
	my $temp = "./taintC$$";
	END { unlink $temp }
	test 87, open(FOO, "> $temp"), "Couldn't open $temp for write: $!";

	test 88, eval { ioctl FOO, $TAINT, $foo } eq '', 'ioctl';
	test 89, $@ =~ /^Insecure dependency/, $@;

	if ($Config{d_fcntl}) {
	    test 90, eval { fcntl FOO, $TAINT, $foo } eq '', 'fcntl';
	    test 91, $@ =~ /^Insecure dependency/, $@;
	}
	else {
	    print "# fcntl() is not available\n";
	    for (90..91) { print "ok $_\n" }
	}

	close FOO;
    }
}

# Some tests involving references
{
    my $foo = 'abc' . $TAINT;
    my $fooref = \$foo;
    test 92, not tainted $fooref;
    test 93, tainted $$fooref;
    test 94, tainted $foo;
}

# Some tests involving assignment
{
    my $foo = $TAINT0;
    my $bar = $foo;
    test 95, all_tainted $foo, $bar;
    test 96, tainted($foo = $bar);
    test 97, tainted($bar = $bar);
    test 98, tainted($bar += $bar);
    test 99, tainted($bar -= $bar);
    test 100, tainted($bar *= $bar);
    test 101, tainted($bar++);
    test 102, tainted($bar /= $bar);
    test 103, tainted($bar += 0);
    test 104, tainted($bar -= 2);
    test 105, tainted($bar *= -1);
    test 106, tainted($bar /= 1);
    test 107, tainted($bar--);
    test 108, $bar == 0;
}

# Test assignment and return of lists
{
    my @foo = ("A", "tainted" . $TAINT, "B");
    test 109, not tainted $foo[0];
    test 110,     tainted $foo[1];
    test 111, not tainted $foo[2];
    my @bar = @foo;
    test 112, not tainted $bar[0];
    test 113,     tainted $bar[1];
    test 114, not tainted $bar[2];
    my @baz = eval { "A", "tainted" . $TAINT, "B" };
    test 115, not tainted $baz[0];
    test 116,     tainted $baz[1];
    test 117, not tainted $baz[2];
    my @plugh = eval q[ "A", "tainted" . $TAINT, "B" ];
    test 118, not tainted $plugh[0];
    test 119,     tainted $plugh[1];
    test 120, not tainted $plugh[2];
    my $nautilus = sub { "A", "tainted" . $TAINT, "B" };
    test 121, not tainted ((&$nautilus)[0]);
    test 122,     tainted ((&$nautilus)[1]);
    test 123, not tainted ((&$nautilus)[2]);
    my @xyzzy = &$nautilus;
    test 124, not tainted $xyzzy[0];
    test 125,     tainted $xyzzy[1];
    test 126, not tainted $xyzzy[2];
    my $red_october = sub { return "A", "tainted" . $TAINT, "B" };
    test 127, not tainted ((&$red_october)[0]);
    test 128,     tainted ((&$red_october)[1]);
    test 129, not tainted ((&$red_october)[2]);
    my @corge = &$red_october;
    test 130, not tainted $corge[0];
    test 131,     tainted $corge[1];
    test 132, not tainted $corge[2];
}
