#!./perl

# t/base/rs.t - $/ variable testing
#
# Test plan
#
# $/ allowed values:
#
#   By default  - "\n"
#   "\n"        - explicit value
#   3           - non line terminator
#   34          - more than one symbol
#   ''          - delimiter as a paragraph
#   undef       - the whole file
#   2           - integer
#   "2"         - string delimiter
#
#   \2          - part symbols count of
#   \"2"        - a delimited string
#
# $/ unallowed values:
#
#   \0       - Setting $/ to a reference to zero is forbidden
#   \-1      - Setting $/ to a reference to a negative integer is forbidden
#   []       - Setting $/ to an ARRAY reference is forbidden
#   {}       - Setting $/ to a HASH reference is forbidden
#   \\1      - Setting $/ to a REF reference is forbidden
#   qr/foo/  - Setting $/ to a REGEXP reference is forbidden
#   \*STDOUT - Setting $/ to a GLOB reference is forbidden
#
# Test preserverd value after trying to set unallowed ones
# Tests for VMS case
# Test $/ by reading file to "my" filehandle variable
# Test $/ by reading file to "our" filehandle variable
# Test $/ for files from variables like real files

print "1..41\n";

# Preparation

$test_count = 1;
$teststring = "1\n12\n123\n1234\n1234\n12345\n\n123456\n1234567\n";
$teststring2 = "1234567890123456789012345678901234567890";

# Remove previous test files if exist
#
# In case of existing files with the same 'foo' name
# on some systems with versioning file system (e.g VMS).
# Read more at pod/perlport.pod "System Interaction"
1 while unlink 'foo';

rmdir 'foo';

# Create test 'foo' file
open TESTFILE, ">./foo" or die "error $! $^E opening";
binmode TESTFILE;
print TESTFILE $teststring;
close TESTFILE or die "error $! $^E closing";

# Check $/ for $test_string from the 'foo' file
$test_count_start = $test_count;  # Needed to know how many tests to skip
open TESTFILE, "<./foo";
binmode TESTFILE;
test_string(*TESTFILE);
close TESTFILE;

unlink "./foo";

# Try the record reading tests. New file so we don't have to worry about
# the size of \n.
open TESTFILE, ">./foo";
print TESTFILE $teststring2;
binmode TESTFILE;
close TESTFILE;

open TESTFILE, "<./foo";
binmode TESTFILE;
test_record(*TESTFILE);
close TESTFILE;
$test_count_end = $test_count;  # Needed to know how many tests to skip

# $/ preserved when set to bad value
$/ = "\n";

# None of the setting of $/ to bad values should modify its value
test_bad_setting();

print +($/ ne "\n" ? "not " : "") .
  "ok $test_count # \$/ preserved when set to bad value\n";
++$test_count;

# VMS case

# Now for the tricky bit--full record reading
if ( $^O eq 'VMS' ) {

    # Create a temp file. We jump through these hoops 'cause CREATE really
    # doesn't like our methods for some reason.
    open FDLFILE, "> ./foo.fdl";
    print FDLFILE "RECORD\n FORMAT VARIABLE\n";
    close FDLFILE;

    open CREATEFILE, "> ./foo.com";
    print CREATEFILE '$ DEFINE/USER SYS$INPUT NL:',  "\n";
    print CREATEFILE '$ DEFINE/USER SYS$OUTPUT NL:', "\n";
    print CREATEFILE '$ OPEN YOW []FOO.BAR/WRITE',   "\n";
    print CREATEFILE '$ CLOSE YOW',                  "\n";
    print CREATEFILE "\$EXIT\n";
    close CREATEFILE;

    $throwaway = `\@\[\]foo`, "\n";

    open( TEMPFILE, ">./foo.bar" ) or die "# open failed $! $^E\n";
    print TEMPFILE "foo\nfoobar\nbaz\n";
    close TEMPFILE;

    open TESTFILE, "<./foo.bar";

    $/ = \10;

    $bar = <TESTFILE>;
    $bar eq "foo\n"
      ? ( print "ok $test_count\n" )
      : ( print "not ok $test_count\n" );

    $test_count++;
    $bar = <TESTFILE>;
    $bar eq "foobar\n"
      ? ( print "ok $test_count\n" )
      : ( print "not ok $test_count\n" );
    $test_count++;

    # Can we do a short read?
    $/ = \2;
    $bar = <TESTFILE>;
    $bar eq "ba"
      ? ( print "ok $test_count\n" )
      : ( print "not ok $test_count\n" );
    $test_count++;

    # Do we get the rest of the record?
    $bar = <TESTFILE>;
    $bar eq "z\n"
      ? ( print "ok $test_count\n" )
      : ( print "not ok $test_count\n" );
    $test_count++;

    close TESTFILE;
    1 while unlink qw(foo.bar foo.com foo.fdl);
}
else {
    # Nobody else does this at the moment (well, maybe OS/390, but they can
    # put their own tests in) so we just punt
    foreach $test ( $test_count .. $test_count + 3 ) {
        print "ok $test # skipped on non-VMS system\n";
        $test_count++;
    }
}

$/ = "\n";

# See if open/readline/close work on our and my variables

# For "our" variable
{
    if ( open our $T, "./foo" ) {
        $line = <$T>;
        print "# $line\n";
        # length of $teststring2
        length($line) == 40 or print "not ";
        close $T            or print "not ";
    }
    else {
        print "not ";
    }
    print "ok $test_count # open/readline/close on our variable\n";
    $test_count++;
}

# For "my" variable
{
    if ( open my $T, "./foo" ) {
        $line = <$T>;
        print "# $line\n";
        length($line) == 40 or print "not ";
        close $T            or print "not ";
    }
    else {
        print "not ";
    }
    print "ok $test_count # open/readline/close on my variable\n";
    $test_count++;
}

{
    # If we do not include the lib directories, we may end up picking up a
    # binary-incompatible previously-installed version. The eval won’t help in
    # intercepting a SIGTRAP.
    local @INC = ("../lib", "lib", @INC);
    if (not eval q/use PerlIO::scalar; 1/) {
        # In-memory files necessitate PerlIO::scalar, thus a perl with
        # perlio and dynaloading enabled. miniperl won't be able to run this
        # test, so skip it

        for $test ( $test_count .. $test_count +
            ( $test_count_end - $test_count_start - 1 ) )
        {
            print "ok $test # skipped - Can't test in memory file "
              . "with miniperl/without PerlIO::Scalar\n";
            $test_count++;
        }
    }
    else {

        # Test if a file in memory behaves the same as a real file (= re-run the test with a file in memory)
        open TESTFILE, "<", \$teststring;
        test_string(*TESTFILE);
        close TESTFILE;

        open TESTFILE, "<", \$teststring2;
        test_record(*TESTFILE);
        close TESTFILE;
    }
}

# Get rid of the temp file
END { unlink "./foo"; }

sub test_string {
    *FH = shift;

    # Check the default $/ which is newline
    $bar = <FH>;
    if ( $bar ne "1\n" ) { print "not "; }
    print "ok $test_count # default \$/\n";
    $test_count++;

    # Explicitly set to \n
    $/   = "\n";
    $bar = <FH>;
    if ( $bar ne "12\n" ) { print "not "; }
    print "ok $test_count # \$/ = \"\\n\"\n";
    $test_count++;

    # Try a non line terminator
    $/   = 3;
    $bar = <FH>;
    if ( $bar ne "123" ) { print "not "; }
    print "ok $test_count # \$/ = 3\n";
    $test_count++;

    # Eat the line terminator
    $/   = "\n";
    $bar = <FH>;

    # How about a larger terminator
    $/   = "34";
    $bar = <FH>;
    if ( $bar ne "1234" ) { print "not "; }
    print "ok $test_count # \$/ = \"34\"\n";
    $test_count++;

    # Eat the line terminator
    $/   = "\n";
    $bar = <FH>;

    # Does paragraph mode work?
    $/   = '';
    $bar = <FH>;
    if ( $bar ne "1234\n12345\n\n" ) { print "not "; }
    print "ok $test_count # \$/ = ''\n";
    $test_count++;

    # Try slurping the rest of the file
    $/   = undef;
    $bar = <FH>;
    if ( $bar ne "123456\n1234567\n" ) { print "not "; }
    print "ok $test_count # \$/ = undef\n";
    $test_count++;
}

sub test_record {
    *FH = shift;

    # Test straight number
    $/ = \2;
    $bar = <FH>;
    if ( $bar ne "12" ) { print "not "; }
    print "ok $test_count # \$/ = \\2\n";
    $test_count++;

    # Test stringified number
    $/   = \"2";
    $bar = <FH>;
    if ( $bar ne "34" ) { print "not "; }
    print "ok $test_count # \$/ = \"2\"\n";
    $test_count++;

    # Integer variable
    $foo = 2;
    $/   = \$foo;
    $bar = <FH>;
    if ( $bar ne "56" ) { print "not "; }
    print "ok $test_count # \$/ = \\\$foo (\$foo = 2)\n";
    $test_count++;

    # String variable
    $foo = "2";
    $/   = \$foo;
    $bar = <FH>;
    if ( $bar ne "78" ) { print "not "; }
    print "ok $test_count # \$/ = \\\$foo (\$foo = \"2\")\n";
    $test_count++;
}

sub test_bad_setting {
    if ( eval { $/ = \0; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = \\0; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = \\0; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = \\0; should die\n";
        if ( $msg !~ m!Setting \$\/ to a reference to zero is forbidden! ) {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = \\0; produced expected error message\n";
    }

    if ( eval { $/ = \-1; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = \\-1; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = \\-1; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = \\-1; should die\n";
        if ( $msg !~
            m!Setting \$\/ to a reference to a negative integer is forbidden! )
        {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = \\-1; produced expected error message\n";
    }

    if ( eval { $/ = []; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = []; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = []; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = []; should die\n";
        if ( $msg !~ m!Setting \$\/ to an ARRAY reference is forbidden! ) {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = []; produced expected error message\n";
    }

    if ( eval { $/ = {}; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = {}; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = {}; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = {}; should die\n";
        if ( $msg !~ m!Setting \$\/ to a HASH reference is forbidden! ) {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = {}; produced expected error message\n";
    }

    if ( eval { $/ = \\1; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = \\\\1; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = \\\\1; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = \\\\1; should die\n";
        if ( $msg !~ m!Setting \$\/ to a REF reference is forbidden! ) {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = \\\\1; produced expected error message\n";
    }

    if ( eval { $/ = qr/foo/; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = qr/foo/; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = qr/foo/; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = qr/foo/; should die\n";
        if ( $msg !~ m!Setting \$\/ to a REGEXP reference is forbidden! ) {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = qr/foo/; produced expected error message\n";
    }

    if ( eval { $/ = \*STDOUT; 1 } ) {
        print "not ok ", $test_count++, " # \$/ = \\*STDOUT; should die\n";
        print "not ok ", $test_count++,
          " # \$/ = \\*STDOUT; produced expected error message\n";
    }
    else {
        $msg = $@ || "Zombie Error";
        print "ok ", $test_count++, " # \$/ = \\*STDOUT; should die\n";
        if ( $msg !~ m!Setting \$\/ to a GLOB reference is forbidden! ) {
            print "not ";
        }
        print "ok ", $test_count++,
          " # \$/ = \\*STDOUT; produced expected error message\n";
    }
}
