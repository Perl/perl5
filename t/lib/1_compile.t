#!./perl

# Modules should have their own tests.  For historical reasons, some
# do not.  This does basic compile tests on modules that have no tests
# of their own.

BEGIN {
    chdir 't';
    @INC = '../lib';
}

use strict;
use warnings;

# Okay, this is the list.

my @Core_Modules = grep /\S/, sort <DATA>;
chomp @Core_Modules;

print "1..".(1+@Core_Modules)."\n";

my $message
  = "ok 1 - All modules should have tests # TODO Make Schwern Poorer\n";
if (@Core_Modules) {
  print "not $message";
} else {
  print $message;
}

my $test_num = 2;

foreach my $module (@Core_Modules) {
    print "$module compile failed\nnot " unless compile_module($module);
    print "ok $test_num\n";
    $test_num++;
}

# We do this as a separate process else we'll blow the hell
# out of our namespace.
sub compile_module {
    my ($module) = $_[0];

    my $out = scalar `$^X "-I../lib" lib/compmod.pl $module`;
    print "# $out";
    return $out =~ /^ok/;
}

# These modules have no tests of their own.
# Keep up to date with
# http://www.pobox.com/~schwern/cgi-bin/perl-qa-wiki.cgi?UntestedModules
# and vice-versa.  The list should only shrink.
__DATA__
B::CC
B::Disassembler
B::Stackobj
ByteLoader
CPAN
CPAN::FirstTime
DynaLoader
ExtUtils::MM_NW5
ExtUtils::Install
ExtUtils::Liblist
ExtUtils::Mksymlists
Net::Cmd
Net::Domain
Net::POP3
O
Pod::Plainer
Test::Harness::Iterator
