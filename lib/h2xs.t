#!./perl

# Some quick tests to see if h2xs actually runs and creates files as 
# expected.  File contents include date stamps and/or usernames
# hence are not checked.  File existence is checked with -e though.
# This test depends on File::Path::rmtree() to clean up with.
#  - pvhp

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# use strict; # we are not really testing this
use File::Path;  # for cleaning up with rmtree()

my $extracted_program = '../utils/h2xs'; # unix, nt, ...
if ($^O eq 'VMS') { $extracted_program = '[-.utils]h2xs.com'; }
if ($^O eq 'MacOS') { $extracted_program = '::utils:h2xs'; }
if (!(-e $extracted_program)) {
    print "1..0 # Skip: $extracted_program was not built\n";
    exit 0;
}
# You might also wish to bail out if your perl platform does not
# do `$^X -e 'warn "Writing h2xst"' 2>&1`; duplicity.

my $dupe = '2>&1'; # ok on unix, nt, VMS, ...
my $lib = '"-I../lib"'; # ok on unix, nt, The extra \" are for VMS
# The >&1 would create a file named &1 on MPW (STDERR && STDOUT are
# already merged).
if ($^O eq 'MacOS') {
    $dupe = '';
    $lib = '-x -I::lib:'; # -x overcomes MPW $Config{startperl} anomaly
}
# $name should differ from system header file names and must
# not already be found in the t/ subdirectory for perl.
my $name = 'h2xst';

print "1..17\n";

my @result = ();
my $result = '';
my $expectation = '';

# h2xs warns about what it is writing hence the (possibly unportable)
# 2>&1 dupe:
# does it run?
@result = `$^X $lib $extracted_program -f -n $name $dupe`;
print(((!$?) ? "" : "not "), "ok 1\n");
$result = join("",@result);

$expectation = <<"EOXSFILES";
Writing $name/$name.pm
Writing $name/$name.xs
Writing $name/Makefile.PL
Writing $name/README
Writing $name/t/1.t
Writing $name/Changes
Writing $name/MANIFEST
EOXSFILES

# accomodate MPW # comment character prependage
if ($^O eq 'MacOS') {
    $result =~ s/#\s*//gs;
}

#print "# expectation is >$expectation<\n";
#print "# result is >$result<\n";
# Was the output the list of files that were expected?
print((($result eq $expectation) ? "" : "not "), "ok 2\n");
# Were the files created?
my $t = 3;
$expectation =~ s/Writing //; # remove leader
foreach (split(/Writing /,$expectation)) {
    chomp;  # remove \n
    if ($^O eq 'MacOS') {
        $_ = ':' . join(':',split(/\//,$_));
        $_ =~ s/$name:t:1.t/$name:t\/1.t/; # is this an h2xs bug?
    }
    print(((-e $_) ? "" : "not "), "ok $t\n");
    $t++;
}

# clean up
rmtree($name);

# does it run with -X and omit the h2xst.xs file?
@result = ();
$result = '';
# The extra \" around -X are for VMS but do no harm on NT or Unix
@result = `$^X $lib $extracted_program \"-X\" -f -n $name $dupe`;
print(((!$?) ? "" : "not "), "ok $t\n");
$t++;
$result = join("",@result);

$expectation = <<"EONOXSFILES";
Writing $name/$name.pm
Writing $name/Makefile.PL
Writing $name/README
Writing $name/t/1.t
Writing $name/Changes
Writing $name/MANIFEST
EONOXSFILES

if ($^O eq 'MacOS') { $result =~ s/#\s*//gs; }
#print $expectation;
#print $result;
print((($result eq $expectation) ? "" : "not "), "ok $t\n");
$t++;
$expectation =~ s/Writing //; # remove leader
foreach (split(/Writing /,$expectation)) {
    chomp;  # remove \n
    if ($^O eq 'MacOS') {
        $_ = ':' . join(':',split(/\//,$_));
        $_ =~ s/$name:t:1.t/$name:t\/1.t/; # is this an h2xs bug?
    }
    print(((-e $_) ? "" : "not "), "ok $t\n");
    $t++;
}

# clean up
rmtree($name);

