#!/usr/bin/perl -w
use strict;

use Getopt::Long;

my @targets = qw(miniperl lib/Config.pm perl test_prep);

my $target = 'test_prep';
my $j = '9';
my $test_should_pass = 1;
my $clean = 1;
my $one_liner;
my $match;
my $force_manifest;
my $test_build;

sub usage {
    die "$0: [--target=...] [-j=4] [--expect-pass=0|1] thing to test";
}

unless(GetOptions('target=s' => \$target,
		  'jobs|j=i' => \$j,
		  'expect-pass=i' => \$test_should_pass,
		  'expect-fail' => sub { $test_should_pass = 0; },
		  'clean!' => \$clean, # mostly for debugging this
		  'one-liner|e=s' => \$one_liner,
                  'match=s' => \$match,
                  'force-manifest' => \$force_manifest,
                  'test-build' => \$test_build,
		 )) {
    usage();
}

my $exe = $target eq 'perl' || $target eq 'test_prep' ? 'perl' : 'miniperl';
my $expected = $target eq 'test_prep' ? 'perl' : $target;

unshift @ARGV, "./$exe", '-Ilib', '-e', $one_liner if defined $one_liner;

usage() unless @ARGV || $match || $test_build;

die "$0: Can't build $target" unless grep {@targets} $target;

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
    if ($clean) {
        # Needed, because files that are build products in this checked out
        # version might be in git in the next desired version.
        system 'git clean -dxf';
        # Needed, because at some revisions the build alters checked out files.
        # (eg pod/perlapi.pod). Also undoes any changes to makedepend.SH
        system 'git reset --hard HEAD';
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

    my $got = ($test_should_pass ? !$ret : $ret) ? 'good' : 'bad';
    if ($ret) {
        print "$got - $fail $desc\n";
    } else {
        print "$got - $pass $desc\n";
    }

    exit($got eq 'bad');
}

sub apply_patch {
    my $patch = shift;

    open my $fh, '|-', 'patch' or die "Can't run patch: $!";
    print $fh $patch;
    close $fh or die "Can't patch perl.c: $?, $!";
}

# Not going to assume that system perl is yet new enough to have autodie
system 'git clean -dxf' and die;

if ($match) {
    my $matches;
    my $re = qr/$match/;
    foreach my $file (`git ls-files`) {
        chomp $file;
        open my $fh, '<', $file or die "Can't open $file: $!";
        while (<$fh>) {
            if ($_ =~ $re) {
                ++$matches;
                $_ .= "\n" unless /\n\z/;
                print "$file: $_";
            }
        }
        close $fh or die "Can't close $file: $!";
    }
    report_and_exit(!$matches, 'matches for', 'no matches for', $match);
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
    
# There was a bug in makedepend.SH which was fixed in version 96a8704c.
# Symptom was './makedepend: 1: Syntax error: Unterminated quoted string'
# Remove this if you're actually bisecting a problem related to makedepend.SH
system 'git show blead:makedepend.SH > makedepend.SH' and die;

my @paths = qw(/usr/local/lib64 /lib64 /usr/lib64);

# if Encode is not needed for the test, you can speed up the bisect by
# excluding it from the runs with -Dnoextensions=Encode
# ccache is an easy win. Remove it if it causes problems.
my @ARGS = ('-des', '-Dusedevel', '-Doptimize=-g', '-Dcc=ccache gcc',
	    '-Dld=gcc', "-Dlibpth=@paths");

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
    push @ARGS, "-Dlibs=@libs";
}

# This seems to be necessary to avoid makedepend becoming confused, and hanging
# on stdin. Seems that the code after make shlist || ...here... is never run.
push @ARGS, q{-Dtrnl='\n'}
    if $major < 4;

push @ARGS, '-Uusenm'
    if $major < 2;

my (@missing, @created_dirs);

if ($force_manifest) {
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

# </dev/null because it seems that some earlier versions of Configure can
# call commands in a way that now has them reading from stdin (and hanging)
my $pid = fork;
die "Can't fork: $!" unless defined $pid;
if (!$pid) {
    # Before dfe9444ca7881e71, Configure would refuse to run if stdin was not a
    # tty. With that commit, the tty requirement was dropped for -de and -dE
    if($major > 4) {
        open STDIN, '<', '/dev/null';
    } elsif (!$force_manifest) {
        # If a file in MANIFEST is missing, Configure asks if you want to
        # continue (the default being 'n'). With stdin closed or /dev/null,
        # it exit immediately and the check for config.sh below will skip.
        # To avoid a hang, we need to check MANIFEST for ourselves, and skip
        # if anything is missing.
        open my $fh, '<', 'MANIFEST';
        skip("Could not open MANIFEST: $!")
            unless $fh;
        while (<$fh>) {
            next unless /^(\S+)/;
            skip("$1 from MANIFEST doesn't exist")
                unless -f $1;
        }
        close $fh or die "Can't close MANIFEST: $!";
    }
    exec './Configure', @ARGS;
    die "Failed to start Configure: $!";
}
waitpid $pid, 0
    or die "wait for Configure, pid $pid failed: $!";

# Skip if something went wrong with Configure
skip('no config.sh') unless -f 'config.sh';

# This is probably way too paranoid:
if (@missing) {
    my @errors;
    foreach my $file (@missing) {
        my (undef, undef, $mode, undef, undef, undef, undef, $size)
            = stat $file;
        if (!defined $mode) {
            push @errors, "Added file $file has been deleted by Configure";
            next;
        }
        if ($mode != 0) {
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
system "make $j miniperl";

if ($target ne 'miniperl') {
    # Nearly all parallel build issues fixed by 5.10.0. Untrustworthy before that.
    $j = '' unless $major > 10;

    if ($target eq 'test_prep') {
        if ($major < 8) {
            # test-prep was added in 5.004_01, 3e3baf6d63945cb6.
            # renamed to test_prep in 2001 in 5fe84fd29acaf55c.
            # earlier than that, just make test. It will be fast enough.
            $target = extract_from_file('Makefile.SH', qr/^(test[-_]prep):/,
                                        'test');
        }
    }

    system "make $j $target";
}

my $missing_target = $expected =~ /perl$/ ? !-x $expected : !-r $expected;

if ($test_build) {
    report_and_exit($missing_target, 'could build', 'could not build', $target);
} elsif ($missing_target) {
    skip("could not build $target");
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
