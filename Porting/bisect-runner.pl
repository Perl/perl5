#!/usr/bin/perl -w
use strict;

use Getopt::Long qw(:config bundling no_auto_abbrev);
use Pod::Usage;
use Config;

my @targets
    = qw(config.sh config.h miniperl lib/Config.pm Fcntl perl test_prep);

my $cpus;
if (open my $fh, '<', '/proc/cpuinfo') {
    while (<$fh>) {
        ++$cpus if /^processor\s+:\s+\d+$/;
    }
} elsif (-x '/sbin/sysctl') {
    $cpus = 1 + $1 if `/sbin/sysctl hw.ncpu` =~ /^hw\.ncpu: (\d+)$/;
} elsif (-x '/usr/bin/getconf') {
    $cpus = 1 + $1 if `/usr/bin/getconf _NPROCESSORS_ONLN` =~ /^(\d+)$/;
}

my %options =
    (
     jobs => defined $cpus ? $cpus + 1 : 2,
     'expect-pass' => 1,
     clean => 1, # mostly for debugging this
    );

my @paths = qw(/usr/local/lib64 /lib64 /usr/lib64);

my %defines =
    (
     usedevel => '',
     optimize => '-g',
     cc => 'ccache gcc',
     ld => 'gcc',
     (`uname -sm` eq "Linux x86_64\n" ? (libpth => \@paths) : ()),
    );

unless(GetOptions(\%options,
                  'target=s', 'jobs|j=i', 'expect-pass=i',
                  'expect-fail' => sub { $options{'expect-pass'} = 0; },
                  'clean!', 'one-liner|e=s', 'match=s', 'force-manifest',
                  'test-build', 'check-args', 'A=s@', 'usage|help|?',
                  'D=s@' => sub {
                      my (undef, $val) = @_;
                      if ($val =~ /\A([^=]+)=(.*)/s) {
                          $defines{$1} = length $2 ? $2 : "\0";
                      } else {
                          $defines{$val} = '';
                      }
                  },
                  'U=s@' => sub {
                      $defines{$_[1]} = undef;
                  },
		 )) {
    pod2usage(exitval => 255, verbose => 1);
}

my ($target, $j, $match) = @options{qw(target jobs match)};

pod2usage(exitval => 255, verbose => 1) if $options{usage};
pod2usage(exitval => 255, verbose => 1)
    unless @ARGV || $match || $options{'test-build'} || defined $options{'one-liner'};

exit 0 if $options{'check-args'};

=head1 NAME

bisect.pl - use git bisect to pinpoint changes

=head1 SYNOPSIS

    # When did this become an error?
    .../Porting/bisect.pl -e 'my $a := 2;'
    # When did this stop being an error?
    .../Porting/bisect.pl --expect-fail -e '1 // 2'
    # When did this stop matching?
    .../Porting/bisect.pl --match '\b(?:PL_)hash_seed_set\b'
    # When did this start matching?
    .../Porting/bisect.pl --expect-fail --match '\buseithreads\b'
    # When did this test program stop working?
    .../Porting/bisect.pl --target=perl -- ./perl -Ilib test_prog.pl
    # When did this first become valid syntax?
    .../Porting/bisect.pl --target=miniperl --end=v5.10.0 \
         --expect-fail -e 'my $a := 2;'
    # What was the last revision to build with these options?
    .../Porting/bisect.pl --test-build -Dd_dosuid

=head1 DESCRIPTION

Together C<bisect.pl> and C<bisect-runner.pl> attempt to automate the use
of C<git bisect> as much as possible. With one command (and no other files)
it's easy to find out

=over 4

=item *

Which commit caused this example code to break?

=item *

Which commit caused this example code to start working?

=item *

Which commit added the first to match this regex?

=item *

Which commit removed the last to match this regex?

=back

usually without needing to know which versions of perl to use as start and
end revisions.

By default C<bisect.pl> will process all options, then use the rest of the
command line as arguments to list C<system> to run a test case. By default,
the test case should pass (exit with 0) on earlier perls, and fail (exit
non-zero) on I<blead>. C<bisect.pl> will use C<bisect-runner.pl> to find the
earliest stable perl version on which the test case passes, check that it
fails on blead, and then use C<bisect-runner.pl> with C<git bisect run> to
find the commit which caused the failure.

Because the test case is the complete argument to C<system>, it is easy to
run something other than the F<perl> built, if necessary. If you need to run
the perl built, you'll probably need to invoke it as C<./perl -Ilib ...>

You need a clean checkout to run a bisect, and you can't use the checkout
which contains F<Porting/bisect.pl> (because C<git bisect>) will check out
a revision before F<Porting/bisect-runner.pl> was added, which
C<git bisect run> needs). If your working checkout is called F<perl>, the
simplest solution is to make a local clone, and run from that. I<i.e.>:

    cd ..
    git clone perl perl2
    cd perl2
    ../perl/Porting/bisect.pl ...

=head1 OPTIONS

=over 4

=item *

--start I<commit-ish>

Earliest revision to test, as a I<commit-ish> (a tag, commit or anything
else C<git> understands as a revision). If not specified, C<bisect.pl> will
search stable perl releases from 5.002 to 5.14.0 until it finds one where
the test case passes.

=item *

--end I<commit-ish>

Most recent revision to test, as a I<commit-ish>. If not specified, defaults
to I<blead>.

=item *

--target I<target>

F<Makefile> target (or equivalent) needed, to run the test case. If specified,
this should be one of

=over 4

=item *

I<config.sh>

Just run C<Configure>

=item *

I<config.h>

Run the various F<*.SH> files to generate F<Makefile>, F<config.h>, I<etc>.

=item *

I<miniperl>

Build F<miniperl>.

=item *

I<lib/Config.pm>

Use F<miniperl> to build F<lib/Config.pm>

=item *

I<Fcntl>

Build F<lib/auto/Fcntl/Fnctl.so> (strictly, C<.$Config{so}>). As L<Fcntl>
is simple XS module present since 5.000, this provides a fast test of
whether XS modules can be built. Note, XS modules are built by F<miniperl>,
hence this target will not build F<perl>.

=item *

I<perl>

Build F<perl>. This also builds pure-Perl modules in F<cpan>, F<dist> and
F<ext>. XS modules (such as L<Fcntl>) are not built.

=item *

I<test_prep>

Build everything needed to run the tests. This is the default if we're
running test code, but is time consuming, as it means building all
XS modules. For older F<Makefile>s, the previous name of C<test-prep>
is automatically substituted. For very old F<Makefile>s, C<make test> is
run, as there is no target provided to just get things ready, and for 5.004
and earlier the tests run very quickly.

=back

=item *

--one-liner 'code to run'

=item *

-e 'code to run'

Example code to run, just like you'd use with C<perl -e>.

This prepends C<./perl -Ilib -e 'code to run'> to the test case given,
or C<./miniperl> if I<target> is C<miniperl>.

(Usually you'll use C<-e> instead of providing a test case in the
non-option arguments to C<bisect.pl>)

C<-E> intentionally isn't supported, as it's an error in 5.8.0 and earlier,
which interferes with detecting errors in the example code itself.

=item *

--expect-fail

The test case should fail for the I<start> revision, and pass for the I<end>
revision. The bisect run will find the first commit where it passes.

=item *

-Dusethreads

=item *

-Uusedevel

=item *

-Accflags=-DNO_MATHOMS

Arguments to pass to F<Configure>. Repeated C<-A> arguments are passed
through as is. C<-D> and C<-U> are processed in order, and override
previous settings for the same parameter.

=item *

--jobs I<jobs>

=item *

-j I<jobs>

Number of C<make> jobs to run in parallel. If F</proc/cpuinfo> exists and
can be parsed, or F</sbin/sysctl> exists and reports C<hw.ncpu>, or
F</usr/bin/getconf> exists and reports C<_NPROCESSORS_ONLN> defaults to 1 +
I<number of CPUs>. Otherwise defaults to 2.

=item *

--match pattern

Instead of running a test program to determine I<pass> or I<fail>, pass
if the given regex matches, and hence search for the commit that removes
the last matching file.

If no I<target> is specified, the match is against all files in the
repository (which is fast). If a I<target> is specified, that target is
built, and the match is against only the built files. C<--expect-fail> can
be used with C<--match> to search for a commit that adds files that match.

=item *

--test-build

Test that the build completes, without running any test case.

By default, if the build for the desired I<target> fails to complete,
F<bisect-runner.pl> reports a I<skip> back to C<git bisect>, the assumption
being that one wants to find a commit which changed state "builds && passes"
to "builds && fails". If instead one is interested in which commit broke the
build (possibly for particular F<Configure> options), use I<--test-build>
to treat a build failure as a failure, not a "skip".

Often this option isn't as useful as it first seems, because I<any> build
failure will be reported to C<git bisect> as a failure, not just the failure
that you're interested in. Generally, to debug a particular problem, it's
more useful to use a I<target> that builds properly at the point of interest,
and then a test case that runs C<make>. For example:

    .../Porting/bisect.pl --start=perl-5.000 --end=perl-5.002 \
        --expect-fail --force-manifest --target=miniperl make perl

will find the first revision capable of building C<DynaLoader> and then
C<perl>, without becoming confused by revisions where C<miniperl> won't
even link.

=item *

--force-manifest

By default, a build will "skip" if any files listed in F<MANIFEST> are not
present. Usually this is useful, as it avoids false-failures. However, there
are some long ranges of commits where listed files are missing, which can
cause a bisect to abort because all that remain are skipped revisions.

In these cases, particularly if the test case uses F<miniperl> and no modules,
it may be more useful to force the build to continue, even if files
F<MANIFEST> are missing.

=item *

--expect-pass [0|1]

C<--expect-pass=0> is equivalent to C<--expect-fail>. I<1> is the default.

=item *

--no-clean

Tell F<bisect-runner.pl> not to clean up after the build. This allows one
to use F<bisect-runner.pl> to build the current particular perl revision for
interactive testing, or for debugging F<bisect-runner.pl>.

Passing this to F<bisect.pl> will likely cause the bisect to fail badly.

=item *

--check-args

Validate the options and arguments, and exit silently if they are valid.

=item *

--usage

=item *

--help

=item *

-?

Display the usage information and exit.

=back

=cut

die "$0: Can't build $target" if defined $target && !grep {@targets} $target;

$j = "-j$j" if $j =~ /\A\d+\z/;

# Sadly, however hard we try, I don't think that it will be possible to build
# modules in ext/ on x86_64 Linux before commit e1666bf5602ae794 on 1999/12/29,
# which updated to MakeMaker 3.7, which changed from using a hard coded ld
# in the Makefile to $(LD). On x86_64 Linux the "linker" is gcc.

sub extract_from_file {
    my ($file, $rx, $default) = @_;
    open my $fh, '<', $file or die "Can't open $file: $!";
    while (<$fh>) {
	my @got = $_ =~ $rx;
	return wantarray ? @got : $got[0]
	    if @got;
    }
    return $default if defined $default;
    return;
}

sub clean {
    if ($options{clean}) {
        # Needed, because files that are build products in this checked out
        # version might be in git in the next desired version.
        system 'git clean -dxf </dev/null';
        # Needed, because at some revisions the build alters checked out files.
        # (eg pod/perlapi.pod). Also undoes any changes to makedepend.SH
        system 'git reset --hard HEAD </dev/null';
    }
}

sub skip {
    my $reason = shift;
    clean();
    warn "skipping - $reason";
    exit 125;
}

sub report_and_exit {
    my ($ret, $pass, $fail, $desc) = @_;

    clean();

    my $got = ($options{'expect-pass'} ? !$ret : $ret) ? 'good' : 'bad';
    if ($ret) {
        print "$got - $fail $desc\n";
    } else {
        print "$got - $pass $desc\n";
    }

    exit($got eq 'bad');
}

sub match_and_exit {
    my $target = shift;
    my $matches = 0;
    my $re = qr/$match/;
    my @files;

    {
        local $/ = "\0";
        @files = defined $target ? `git ls-files -o -z`: `git ls-files -z`;
        chomp @files;
    }

    foreach my $file (@files) {
        open my $fh, '<', $file or die "Can't open $file: $!";
        while (<$fh>) {
            if ($_ =~ $re) {
                ++$matches;
                if (tr/\t\r\n -~\200-\377//c) {
                    print "Binary file $file matches\n";
                } else {
                    $_ .= "\n" unless /\n\z/;
                    print "$file: $_";
                }
            }
        }
        close $fh or die "Can't close $file: $!";
    }
    report_and_exit(!$matches,
                    $matches == 1 ? '1 match for' : "$matches matches for",
                    'no matches for', $match);
}

sub apply_patch {
    my $patch = shift;

    my ($file) = $patch =~ qr!^diff.*a/(\S+) b/\1!;
    open my $fh, '|-', 'patch', '-p1' or die "Can't run patch: $!";
    print $fh $patch;
    close $fh or die "Can't patch $file: $?, $!";
}

# Not going to assume that system perl is yet new enough to have autodie
system 'git clean -dxf </dev/null' and die;

if (!defined $target) {
    match_and_exit() if $match;
    $target = 'test_prep';
}

skip('no Configure - is this the //depot/perlext/Compiler branch?')
    unless -f 'Configure';

# This changes to PERL_VERSION in 4d8076ea25903dcb in 1999
my $major
    = extract_from_file('patchlevel.h',
			qr/^#define\s+(?:PERL_VERSION|PATCHLEVEL)\s+(\d+)\s/,
			0);

if ($major < 1) {
    if (extract_from_file('Configure',
                          qr/^		\*=\*\) echo "\$1" >> \$optdef;;$/)) {
        # This is "        Spaces now allowed in -D command line options.",
        # part of commit ecfc54246c2a6f42
        apply_patch(<<'EOPATCH');
diff --git a/Configure b/Configure
index 3d3b38d..78ffe16 100755
--- a/Configure
+++ b/Configure
@@ -652,7 +777,8 @@ while test $# -gt 0; do
 			echo "$me: use '-U symbol=', not '-D symbol='." >&2
 			echo "$me: ignoring -D $1" >&2
 			;;
-		*=*) echo "$1" >> $optdef;;
+		*=*) echo "$1" | \
+				sed -e "s/'/'\"'\"'/g" -e "s/=\(.*\)/='\1'/" >> $optdef;;
 		*) echo "$1='define'" >> $optdef;;
 		esac
 		shift
EOPATCH
    }
    if (extract_from_file('Configure', qr/^if \$contains 'd_namlen' \$xinc\b/)) {
        # Configure's original simple "grep" for d_namlen falls foul of the
        # approach taken by the glibc headers:
        # #ifdef _DIRENT_HAVE_D_NAMLEN
        # # define _D_EXACT_NAMLEN(d) ((d)->d_namlen)
        #
        # where _DIRENT_HAVE_D_NAMLEN is not defined on Linux.
        # This is also part of commit ecfc54246c2a6f42
        apply_patch(<<'EOPATCH');
diff --git a/Configure b/Configure
index 3d3b38d..78ffe16 100755
--- a/Configure
+++ b/Configure
@@ -3935,7 +4045,8 @@ $rm -f try.c
 
 : see if the directory entry stores field length
 echo " "
-if $contains 'd_namlen' $xinc >/dev/null 2>&1; then
+$cppstdin $cppflags $cppminus < "$xinc" > try.c
+if $contains 'd_namlen' try.c >/dev/null 2>&1; then
 	echo "Good, your directory entry keeps length information in d_namlen." >&4
 	val="$define"
 else
EOPATCH
    }
}

if ($major < 5 && extract_from_file('Configure',
                                    qr/^if test ! -t 0; then$/)) {
    # Before dfe9444ca7881e71, Configure would refuse to run if stdin was not a
    # tty. With that commit, the tty requirement was dropped for -de and -dE
    # For those older versions, it's probably easiest if we simply remove the
    # sanity test.
    apply_patch(<<'EOPATCH');
diff --git a/Configure b/Configure
index 0071a7c..8a61caa 100755
--- a/Configure
+++ b/Configure
@@ -93,7 +93,2 @@ esac
 
-: Sanity checks
-if test ! -t 0; then
-	echo "Say 'sh $me', not 'sh <$me'"
-	exit 1
-fi
 
EOPATCH
}

if ($major < 10 && extract_from_file('Configure', qr/^set malloc\.h i_malloc$/)) {
    # This is commit 01d07975f7ef0e7d, trimmed, with $compile inlined as
    # prior to bd9b35c97ad661cc Configure had the malloc.h test before the
    # definition of $compile.
    apply_patch(<<'EOPATCH');
diff --git a/Configure b/Configure
index 3d2e8b9..6ce7766 100755
--- a/Configure
+++ b/Configure
@@ -6743,5 +6743,22 @@ set d_dosuid
 
 : see if this is a malloc.h system
-set malloc.h i_malloc
-eval $inhdr
+: we want a real compile instead of Inhdr because some systems have a
+: malloc.h that just gives a compile error saying to use stdlib.h instead
+echo " "
+$cat >try.c <<EOCP
+#include <stdlib.h>
+#include <malloc.h>
+int main () { return 0; }
+EOCP
+set try
+if $cc $optimize $ccflags $ldflags -o try $* try.c $libs > /dev/null 2>&1; then
+    echo "<malloc.h> found." >&4
+    val="$define"
+else
+    echo "<malloc.h> NOT found." >&4
+    val="$undef"
+fi
+$rm -f try.c try
+set i_malloc
+eval $setvar
 
EOPATCH
}

# There was a bug in makedepend.SH which was fixed in version 96a8704c.
# Symptom was './makedepend: 1: Syntax error: Unterminated quoted string'
# Remove this if you're actually bisecting a problem related to makedepend.SH
system 'git show blead:makedepend.SH > makedepend.SH </dev/null' and die;

if ($^O eq 'freebsd') {
    # There are rather too many version-specific FreeBSD hints fixes to patch
    # individually. Also, more than once the FreeBSD hints file has been
    # written in what turned out to be a rather non-future-proof style,
    # with case statements treating the most recent version as the exception,
    # instead of treating previous versions' behaviour explicitly and changing
    # the default to cater for the current behaviour. (As strangely, future
    # versions inherit the current behaviour.)
    system 'git show blead:hints/freebsd.sh > hints/freebsd.sh </dev/null'
      and die;

    if ($major < 2) {
        # 5.002 Configure and later have code to
        #
        # : Try to guess additional flags to pick up local libraries.
        #
        # which will automatically add --L/usr/local/lib because libpth
        # contains /usr/local/lib
        #
        # Without it, if Configure finds libraries in /usr/local/lib (eg
        # libgdbm.so) and adds them to the compiler commandline (as -lgdbm),
        # then the link will fail. We can't fix this up in config.sh because
        # the link will *also* fail in the test compiles that Configure does
        # (eg $inlibc) which makes Configure get all sorts of things
        # wrong. :-( So bodge it here.
        #
        # Possibly other platforms will need something similar. (if they
        # have "wanted" libraries in /usr/local/lib, but the compiler
        # doesn't default to putting that directory in its link path)
        apply_patch(<<'EOPATCH');
--- perl2/hints/freebsd.sh.orig	2011-10-05 16:44:55.000000000 +0200
+++ perl2/hints/freebsd.sh	2011-10-05 16:45:52.000000000 +0200
@@ -125,7 +125,7 @@
         else
             libpth="/usr/lib /usr/local/lib"
             glibpth="/usr/lib /usr/local/lib"
-            ldflags="-Wl,-E "
+            ldflags="-Wl,-E -L/usr/local/lib "
             lddlflags="-shared "
         fi
         cccdlflags='-DPIC -fPIC'
@@ -133,7 +133,7 @@
 *)
        libpth="/usr/lib /usr/local/lib"
        glibpth="/usr/lib /usr/local/lib"
-       ldflags="-Wl,-E "
+       ldflags="-Wl,-E -L/usr/local/lib "
         lddlflags="-shared "
         cccdlflags='-DPIC -fPIC'
        ;;
EOPATCH
    }
}

# if Encode is not needed for the test, you can speed up the bisect by
# excluding it from the runs with -Dnoextensions=Encode
# ccache is an easy win. Remove it if it causes problems.
# Commit 1cfa4ec74d4933da adds ignore_versioned_solibs to Configure, and sets it
# to true in hints/linux.sh
# On dromedary, from that point on, Configure (by default) fails to find any
# libraries, because it scans /usr/local/lib /lib /usr/lib, which only contain
# versioned libraries. Without -lm, the build fails.
# Telling /usr/local/lib64 /lib64 /usr/lib64 works from that commit onwards,
# until commit faae14e6e968e1c0 adds it to the hints.
# However, prior to 1cfa4ec74d4933da telling Configure the truth doesn't work,
# because it will spot versioned libraries, pass them to the compiler, and then
# bail out pretty early on. Configure won't let us override libswanted, but it
# will let us override the entire libs list.

unless (extract_from_file('Configure', 'ignore_versioned_solibs')) {
    # Before 1cfa4ec74d4933da, so force the libs list.

    my @libs;
    # This is the current libswanted list from Configure, less the libs removed
    # by current hints/linux.sh
    foreach my $lib (qw(sfio socket inet nsl nm ndbm gdbm dbm db malloc dl dld
			ld sun m crypt sec util c cposix posix ucb BSD)) {
	foreach my $dir (@paths) {
	    next unless -f "$dir/lib$lib.so";
	    push @libs, "-l$lib";
	    last;
	}
    }
    $defines{libs} = \@libs unless exists $defines{libs};
}

# This seems to be necessary to avoid makedepend becoming confused, and hanging
# on stdin. Seems that the code after make shlist || ...here... is never run.
$defines{trnl} = q{'\n'}
    if $major < 4 && !exists $defines{trnl};

$defines{usenm} = undef
    if $major < 2 && !exists $defines{usenm};

my (@missing, @created_dirs);

if ($options{'force-manifest'}) {
    open my $fh, '<', 'MANIFEST'
        or die "Could not open MANIFEST: $!";
    while (<$fh>) {
        next unless /^(\S+)/;
        push @missing, $1
            unless -f $1;
    }
    close $fh or die "Can't close MANIFEST: $!";

    foreach my $pathname (@missing) {
        my @parts = split '/', $pathname;
        my $leaf = pop @parts;
        my $path = '.';
        while (@parts) {
            $path .= '/' . shift @parts;
            next if -d $path;
            mkdir $path, 0700 or die "Can't create $path: $!";
            unshift @created_dirs, $path;
        }
        open $fh, '>', $pathname or die "Can't open $pathname: $!";
        close $fh or die "Can't close $pathname: $!";
        chmod 0, $pathname or die "Can't chmod 0 $pathname: $!";
    }
}

my @ARGS = $target eq 'config.sh' ? '-dEs' : '-des';
foreach my $key (sort keys %defines) {
    my $val = $defines{$key};
    if (ref $val) {
        push @ARGS, "-D$key=@$val";
    } elsif (!defined $val) {
        push @ARGS, "-U$key";
    } elsif (!length $val) {
        push @ARGS, "-D$key";
    } else {
        $val = "" if $val eq "\0";
        push @ARGS, "-D$key=$val";
    }
}
push @ARGS, map {"-A$_"} @{$options{A}};

# </dev/null because it seems that some earlier versions of Configure can
# call commands in a way that now has them reading from stdin (and hanging)
my $pid = fork;
die "Can't fork: $!" unless defined $pid;
if (!$pid) {
    open STDIN, '<', '/dev/null';
    # If a file in MANIFEST is missing, Configure asks if you want to
    # continue (the default being 'n'). With stdin closed or /dev/null,
    # it exits immediately and the check for config.sh below will skip.
    exec './Configure', @ARGS;
    die "Failed to start Configure: $!";
}
waitpid $pid, 0
    or die "wait for Configure, pid $pid failed: $!";

if ($target =~ /config\.s?h/) {
    match_and_exit($target) if $match && -f $target;
    report_and_exit(!-f $target, 'could build', 'could not build', $target);
} elsif (!-f 'config.sh') {
    # Skip if something went wrong with Configure

    skip('could not build config.sh');
}

# This is probably way too paranoid:
if (@missing) {
    my @errors;
    require Fcntl;
    foreach my $file (@missing) {
        my (undef, undef, $mode, undef, undef, undef, undef, $size)
            = stat $file;
        if (!defined $mode) {
            push @errors, "Added file $file has been deleted by Configure";
            next;
        }
        if (Fcntl::S_IMODE($mode) != 0) {
            push @errors,
                sprintf 'Added file %s had mode changed by Configure to %03o',
                    $file, $mode;
        }
        if ($size != 0) {
            push @errors,
                "Added file $file had sized changed by Configure to $size";
        }
        unlink $file or die "Can't unlink $file: $!";
    }
    foreach my $dir (@created_dirs) {
        rmdir $dir or die "Can't rmdir $dir: $!";
    }
    skip("@errors")
        if @errors;
}

# Correct makefile for newer GNU gcc
# Only really needed if you comment out the use of blead's makedepend.SH
{
    local $^I = "";
    local @ARGV = qw(makefile x2p/makefile);
    while (<>) {
	print unless /<(?:built-in|command|stdin)/;
    }
}

if ($major == 2 && extract_from_file('perl.c', qr/^	fclose\(e_fp\);$/)) {
    # need to patch perl.c to avoid calling fclose() twice on e_fp when using -e
    # This diff is part of commit ab821d7fdc14a438. The second close was
    # introduced with perl-5.002, commit a5f75d667838e8e7
    # Might want a6c477ed8d4864e6 too, for the corresponding change to pp_ctl.c
    # (likely without this, eval will have "fun")
    apply_patch(<<'EOPATCH');
diff --git a/perl.c b/perl.c
index 03c4d48..3c814a2 100644
--- a/perl.c
+++ b/perl.c
@@ -252,6 +252,7 @@ setuid perl scripts securely.\n");
 #ifndef VMS  /* VMS doesn't have environ array */
     origenviron = environ;
 #endif
+    e_tmpname = Nullch;
 
     if (do_undump) {
 
@@ -405,6 +406,7 @@ setuid perl scripts securely.\n");
     if (e_fp) {
 	if (Fflush(e_fp) || ferror(e_fp) || fclose(e_fp))
 	    croak("Can't write to temp file for -e: %s", Strerror(errno));
+	e_fp = Nullfp;
 	argc++,argv--;
 	scriptname = e_tmpname;
     }
@@ -470,10 +472,10 @@ setuid perl scripts securely.\n");
     curcop->cop_line = 0;
     curstash = defstash;
     preprocess = FALSE;
-    if (e_fp) {
-	fclose(e_fp);
-	e_fp = Nullfp;
+    if (e_tmpname) {
 	(void)UNLINK(e_tmpname);
+	Safefree(e_tmpname);
+	e_tmpname = Nullch;
     }
 
     /* now that script is parsed, we can modify record separator */
@@ -1369,7 +1371,7 @@ SV *sv;
 	scriptname = xfound;
     }
 
-    origfilename = savepv(e_fp ? "-e" : scriptname);
+    origfilename = savepv(e_tmpname ? "-e" : scriptname);
     curcop->cop_filegv = gv_fetchfile(origfilename);
     if (strEQ(origfilename,"-"))
 	scriptname = "";

EOPATCH
}

# Parallel build for miniperl is safe
system "make $j miniperl </dev/null";

my $expected = $target =~ /^test/ ? 't/perl'
    : $target eq 'Fcntl' ? "lib/auto/Fcntl/Fcntl.$Config{so}"
    : $target;
my $real_target = $target eq 'Fcntl' ? $expected : $target;

if ($target ne 'miniperl') {
    # Nearly all parallel build issues fixed by 5.10.0. Untrustworthy before that.
    $j = '' if $major < 10;

    if ($real_target eq 'test_prep') {
        if ($major < 8) {
            # test-prep was added in 5.004_01, 3e3baf6d63945cb6.
            # renamed to test_prep in 2001 in 5fe84fd29acaf55c.
            # earlier than that, just make test. It will be fast enough.
            $real_target = extract_from_file('Makefile.SH',
                                             qr/^(test[-_]prep):/,
                                             'test');
        }
    }

    if ($major < 10
	and -f 'ext/IPC/SysV/SysV.xs',
	and my ($line) = extract_from_file('ext/IPC/SysV/SysV.xs',
					   qr!^(# *include <asm/page.h>)$!)) {
	apply_patch(<<"EOPATCH");
diff --git a/ext/IPC/SysV/SysV.xs b/ext/IPC/SysV/SysV.xs
index 35a8fde..62a7965 100644
--- a/ext/IPC/SysV/SysV.xs
+++ b/ext/IPC/SysV/SysV.xs
\@\@ -4,7 +4,6 \@\@
 
 #include <sys/types.h>
 #ifdef __linux__
-$line
 #endif
 #if defined(HAS_MSG) || defined(HAS_SEM) || defined(HAS_SHM)
 #ifndef HAS_SEM
EOPATCH
    }
    system "make $j $real_target </dev/null";
}

my $missing_target = $expected =~ /perl$/ ? !-x $expected : !-r $expected;

if ($options{'test-build'}) {
    report_and_exit($missing_target, 'could build', 'could not build',
                    $real_target);
} elsif ($missing_target) {
    skip("could not build $real_target");
}

match_and_exit($real_target) if $match;

if (defined $options{'one-liner'}) {
    my $exe = $target =~ /^(?:perl$|test)/ ? 'perl' : 'miniperl';
    unshift @ARGV, "./$exe", '-Ilib', '-e', $options{'one-liner'};
}

# This is what we came here to run:
my $ret = system @ARGV;

report_and_exit($ret, 'zero exit from', 'non-zero exit from', "@ARGV");

# Local variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# ex: set ts=8 sts=4 sw=4 et:
