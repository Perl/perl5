#!./perl -w

print "1..8\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use warnings;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Constant qw (constant_types C_constant XS_constant autoload);
use Config;

my $runperl = $^X;
my $tobitbucket = ">/dev/null";
# my @cleanup;
$| = 1;

my $dir = "ext-$$";
mkdir $dir, 0777 or die $!;

END {
  system "$Config{rm} -rf $dir";
}

# push @cleanup, $dir;

my @names = ("THREE", {name=>"OK4", type=>"PV",},
             {name=>"OK5", type=>"PVN",
              value=>['"not ok 5\\n\\0ok 5\\n"', 15]},
             {name => "FARTHING", type=>"NV"},
             {name => "NOT_ZERO", type=>"UV", value=>~0 . "u"});

my @names_only = map {(ref $_) ? $_->{name} : $_} @names;

my $package = "ExtTest";
################ Header
my $header = "$dir/test.h";
open FH, ">$header" or die $!;
print FH <<'EOT';
#define THREE 3
#define OK4 "ok 4\n"
#define OK5 1
#define FARTHING 0.25
#define NOT_ZERO 1
EOT
close FH or die $!;
# push @cleanup, $header;

################ XS
my $xs = "$dir/$package.xs";
open FH, ">$xs" or die $!;

print FH <<'EOT';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
EOT

print FH "#include \"test.h\"\n\n";
print FH constant_types(); # macro defs
my $types = {};
foreach (C_constant (undef, "IV", $types, undef, undef, @names) ) {
  print FH $_, "\n"; # C constant subs
}
print FH "MODULE = $package		PACKAGE = $package\n";
print FH "PROTOTYPES: ENABLE\n";
print FH XS_constant ($package, $types); # XS for ExtTest::constant
close FH or die $!;
# push @cleanup, $xs;

################ PM
my $pm = "$dir/$package.pm";
open FH, ">$pm" or die $!;
print FH "package $package;\n";
print FH "use $];\n";

print FH <<'EOT';

use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;
use vars qw ($VERSION @ISA @EXPORT_OK);

$VERSION = '0.01';
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(
EOT

print FH "\t$_\n" foreach (@names_only);
print FH ");\n";
print FH autoload ($package, $]);
print FH "bootstrap $package \$VERSION;\n1;\n__END__\n";
close FH or die $!;
# push @cleanup, $pm;

################ test.pl
my $testpl = "$dir/test.pl";
open FH, ">$testpl" or die $!;

print FH "use $package qw(@names_only);\n";
print FH <<'EOT';

my $three = THREE;
if ($three == 3) {
  print "ok 3\n";
} else {
  print "not ok 3 # $three\n";
}

print OK4;

$_ = OK5;
s/.*\0//s;
print;

my $farthing = FARTHING;
if ($farthing == 0.25) {
  print "ok 6\n";
} else {
  print "not ok 6 # $farthing\n";
}

my $not_zero = NOT_ZERO;
if ($not_zero > 0 && $not_zero == ~0) {
  print "ok 7\n";
} else {
  print "not ok 7 # \$not_zero=$not_zero ~0=" . (~0) . "\n";
}


EOT

close FH or die $!;
# push @cleanup, $testpl;

################ dummy Makefile.PL
# Keep the dependancy in the Makefile happy
my $makefilePL = "$dir/Makefile.PL";
open FH, ">$makefilePL" or die $!;
close FH or die $!;
# push @cleanup, $makefilePL;

chdir $dir or die $!; push @INC,  '../../lib';
END {chdir ".." or warn $!};

print "# "; # Grr. MakeMaker hardwired to write its message to STDOUT
WriteMakefile(
              'NAME'		=> $package,
              'VERSION_FROM'	=> "$package.pm", # finds $VERSION
              ($] >= 5.005 ?
               (#ABSTRACT_FROM => "$package.pm", # XXX add this
                AUTHOR     => $0) : ())
             );
if (-f "Makefile") {
  print "ok 1\n";
} else {
  print "not ok 1\n";
}

my $make = $Config{make};
$make = $ENV{MAKE} if exists $ENV{MAKE};
print "# make = '$make'\n";
if (system "$make $tobitbucket") {
  print "not ok 2 # $make failed\n";
  # Bail out?
} else {
  print "ok 2\n";
}

$make .= ' test';
# This hack to get a # in front of "PERL_DL_NONLAZY=1 ..." isn't going to work
# on VMS mailboxes.
print "# make = '$make'\n# ";
if (system $make) {
  print "not ok 8 # $make failed\n";
} else {
  print "ok 8\n";
}
