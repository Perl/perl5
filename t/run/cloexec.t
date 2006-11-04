#!./perl
#
# Test inheriting file descriptors across exec (close-on-exec).
#
# perlvar describes $^F aka $SYSTEM_FD_MAX as follows:
#
#  The maximum system file descriptor, ordinarily 2.  System file
#  descriptors are passed to exec()ed processes, while higher file
#  descriptors are not.  Also, during an open(), system file descriptors
#  are preserved even if the open() fails.  (Ordinary file descriptors
#  are closed before the open() is attempted.)  The close-on-exec
#  status of a file descriptor will be decided according to the value of
#  C<$^F> when the corresponding file, pipe, or socket was opened, not
#  the time of the exec().
#
# This documented close-on-exec behaviour is typically implemented in
# various places (e.g. pp_sys.c) with code something like:
#
#  #if defined(HAS_FCNTL) && defined(F_SETFD)
#      fcntl(fd, F_SETFD, fd > PL_maxsysfd);  /* ensure close-on-exec */
#  #endif
#
# This behaviour, therefore, is only currently implemented for platforms
# where:
#
#  a) HAS_FCNTL and F_SETFD are both defined
#  b) Integer fds are native OS handles
#
# ... which is typically just the Unix-like platforms.
#
# Notice that though integer fds are supported by the C runtime library
# on Windows, they are not native OS handles, and so are not inherited
# across an exec (though native Windows file handles are).

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    use Config;
    if (!$Config{'d_fcntl'}) {
        print("1..0 # Skip: fcntl() is not available\n");
        exit(0);
    }
    require './test.pl';
}

use strict;

$|=1;

my $Is_VMS      = $^O eq 'VMS';
my $Is_MacOS    = $^O eq 'MacOS';
my $Is_Win32    = $^O eq 'MSWin32';
my $Is_Cygwin   = $^O eq 'cygwin';

# When in doubt, skip.
skip_all("MacOS")    if $Is_MacOS;
skip_all("VMS")      if $Is_VMS;
skip_all("cygwin")   if $Is_Cygwin;
skip_all("Win32")    if $Is_Win32;

sub make_tmp_file {
    my ($fname, $fcontents) = @_;
    local *FHTMP;
    open   FHTMP, ">$fname"  or die "open  '$fname': $!";
    print  FHTMP $fcontents  or die "print '$fname': $!";
    close  FHTMP             or die "close '$fname': $!";
}

my $Perl = which_perl();
my $quote = $Is_VMS || $Is_Win32 ? '"' : "'";

my $tmperr             = 'cloexece.tmp';
my $tmpfile1           = 'cloexec1.tmp';
my $tmpfile2           = 'cloexec2.tmp';
my $tmpfile1_contents  = "tmpfile1 line 1\ntmpfile1 line 2\n";
my $tmpfile2_contents  = "tmpfile2 line 1\ntmpfile2 line 2\n";
make_tmp_file($tmpfile1, $tmpfile1_contents);
make_tmp_file($tmpfile2, $tmpfile2_contents);

# $Child_prog is the program run by the child that inherits the fd.
# Note: avoid using ' or " in $Child_prog since it is run with -e
my $Child_prog = <<'CHILD_PROG';
my $fd = shift;
print qq{childfd=$fd\n};
open INHERIT, qq{<&=$fd} or die qq{open $fd: $!};
my $line = <INHERIT>;
close INHERIT or die qq{close $fd: $!};
print $line
CHILD_PROG
$Child_prog =~ tr/\n//d;

plan(tests => 29);

sub test_not_inherited {
    my $expected_fd = shift;
    ok( -f $tmpfile2, "tmpfile '$tmpfile2' exists" );
    local *FHPARENT2;
    open FHPARENT2, "<$tmpfile2" or die "open '$tmpfile2': $!";
    my $parentfd = fileno FHPARENT2;
    defined $parentfd or die "fileno: $!";
    cmp_ok( $parentfd, '==', $expected_fd, "parent open fd=$parentfd" );
    my $cmd = qq{$Perl -e $quote$Child_prog$quote $parentfd};
    # Expect 'Bad file descriptor' or similar to be written to STDERR.
    local *SAVERR; open SAVERR, ">&STDERR";  # save original STDERR
    open STDERR, ">$tmperr" or die "open '$tmperr': $!";
    my $out = `$cmd`;
    my $rc  = $? >> 8;
    open STDERR, ">&SAVERR" or die "error: restore STDERR: $!";
    close SAVERR or die "error: close SAVERR: $!";
    cmp_ok( $rc, '!=', 0,
        "child return code=$rc (non-zero means cannot inherit fd=$parentfd)" );
    cmp_ok( $out =~ tr/\n//, '==', 1,   'child stdout: has 1 newline' );
    is( $out, "childfd=$expected_fd\n", 'child stdout: fd' );
    close FHPARENT2 or die "close '$tmpfile2': $!";
}

sub test_inherited {
    my $expected_fd = shift;
    ok( -f $tmpfile1, "tmpfile '$tmpfile1' exists" );
    local *FHPARENT1;
    open FHPARENT1, "<$tmpfile1" or die "open-1 '$tmpfile1': $!";
    my $parentfd = fileno FHPARENT1;
    defined $parentfd or die "fileno: $!";
    cmp_ok( $parentfd, '==', $expected_fd, "parent open fd=$parentfd" );
    my $cmd = qq{$Perl -e $quote$Child_prog$quote $parentfd};
    my $out = `$cmd`;
    my $rc  = $? >> 8;
    cmp_ok( $rc, '==', 0,
        "child return code=$rc (zero means inherited fd=$parentfd ok)" );
    my @lines = split(/^/, $out);
    cmp_ok( $out =~ tr/\n//, '==', 2, 'child stdout: has 2 newlines' );
    cmp_ok( scalar(@lines),  '==', 2, 'child stdout: split into 2 lines' );
    is( $lines[0], "childfd=$expected_fd\n", 'child stdout: fd' );
    is( $lines[1], "tmpfile1 line 1\n",      'child stdout: line 1' );
    close FHPARENT1 or die "close '$tmpfile1': $!";
}

$^F == 2 or print STDERR "# warning: \$^F is $^F (not 2)\n";

# Should not be able to inherit $^F+1 in the default case.
test_not_inherited($^F+1);

# Should be able to inherit $^F after incrementing it.
++$^F;
test_inherited($^F);
# ... and test that you cannot inherit fd = $^F+1.
open FHPARENT1, "<$tmpfile1" or die "open '$tmpfile1': $!";
test_not_inherited($^F+1);
close FHPARENT1 or die "close '$tmpfile1': $!";
# ... and now you can inherit after incrementing.
++$^F;
open FHPARENT2, "<$tmpfile2" or die "open '$tmpfile2': $!";
test_inherited($^F);
close FHPARENT2 or die "close '$tmpfile2': $!";

# Re-test default case after decrementing.
--$^F; --$^F;
test_not_inherited($^F+1);

END {
    defined $tmperr   and unlink($tmperr);
    defined $tmpfile1 and unlink($tmpfile1);
    defined $tmpfile2 and unlink($tmpfile2);
}
