# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Archive::Tar;
use File::Find;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$^W=1;
my $t1 = Archive::Tar->new ();
open TT, "MANIFEST";
my @files = <TT>;
close TT;
chomp @files;
find sub {push @files, $File::Find::name;}, "blib";
undef $/;
open TT, "test.pl";
my $data1 = <TT>;
close TT;
print $t1->add_files (@files) 
    ? "ok 2\n" : "not ok 2\n";
print $t1->add_data ('xtest.pl', $data1)
    ? "ok 3\n" : "not ok 3\n";
print $t1->write ("dummy.tar", 9) || $t1->write ("dummy.tar")
    ? "ok 4\n" : "not ok 4\n";
undef $t1;

package MyTest;

@ISA = 'Archive::Tar';
my $t2 = MyTest->new ("dummy.tar");
print $t2 
    ? "ok 5\n" : "not ok 5\n";
my $data2 = $t2->get_content ('xtest.pl');
print $data1 eq $data2 
    ? "ok 6\n" : "not ok 6\n";
$data2 = $t2->get_content ('test.pl');
print $data1 eq $data2 
    ? "ok 7\n" : "not ok 7\n";
print $t2->read ("this/does/not/exist")
    ? "not ok 8\n" : "ok 8\n";
print $t2->error
    ? "ok 9\n" : "not ok 9\n";
$t2->set_error ("a new error");
print $t2->error eq "a new error"
    ? "ok 10\n" : "not ok 10\n";

unlink "dummy.tar";

1;
