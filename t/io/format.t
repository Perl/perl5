#!/usr/bin/perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..33\n";

use strict;	# Amazed that this hackery can be made strict ...

# Just a complete test for format, including top-, left- and bottom marging
# and format detection through glob entries

   $=  =  7;		# Page length
my $ps = $^L; $^L = "";	# Catch the page separator
my $tm =  1;		# Top margin (empty lines before first output)
my $bm =  2;		# Bottom marging (empty lines between last text and footer)
my $lm =  4;		# Left margin (indent in spaces)

if ($lm > 0 and !open STDOUT, "|-") {	# Left margin (in this test ALWAYS set)
    my $i = 1;
    my $s = " " x $lm;
    while (<STDIN>) {
	s/^/$s/;
	print + ($_ eq <DATA> ? "" : "not "), "ok ", $i++, "\n";
	}
    close STDIN;
    print + (<DATA>?"not ":""), "ok ", $i++, "\n";
    close STDOUT;
    exit;
    }
$tm = "\n" x $tm;
$= -= $bm + 1; # count one for the trailing "----"
my $lastmin = 0;

my @E;

sub wryte
{
    $lastmin = $-;
    write;
    } # wryte;

sub footer
{
    $% == 1 and return "";

    $lastmin < $= and print "\n" x $lastmin;
    print "\n" x $bm, "----\n", $ps;
    $lastmin = $-;
    "";
    } # footer

# Yes, this is sick ;-)
format TOP =
@* ~
@{[footer]}
@* ~
$tm
.

format EmptyTOP =
.

format ENTRY =
@ @<<<<~~
@{(shift @E)||["",""]}
.

format EOR =
- -----
.

sub has_format ($)
{
    my $fmt = shift;
    exists $::{$fmt} or return 0;
    $^O eq "MSWin32" or return defined *{$::{$fmt}}{FORMAT};
    open my $null, "> /dev/null" or die;
    my $fh = select $null;
    local $~ = $fmt;
    eval "write";
    select $fh;
    $@?0:1;
    } # has_format

$^ = has_format ("TOP") ? "TOP" : "EmptyTOP";
has_format ("ENTRY") or die "No format defined for ENTRY";
foreach my $e ( [ map { [ $_, "Test$_"   ] } 1 .. 7 ],
		[ map { [ $_, "${_}tseT" ] } 1 .. 5 ]) {
    @E = @$e;
    local $~ = "ENTRY";
    wryte;
    has_format ("EOR") or next;
    local $~ = "EOR";
    wryte;
    }
if (has_format ("EOF")) {
    local $~ = "EOF";
    wryte;
    }

close STDOUT;

__END__
    
    1 Test1
    2 Test2
    3 Test3
    
    
    ----
    
    4 Test4
    5 Test5
    6 Test6
    
    
    ----
    
    7 Test7
    - -----
    
    
    
    ----
    
    1 1tseT
    2 2tseT
    3 3tseT
    
    
    ----
    
    4 4tseT
    5 5tseT
    - -----
