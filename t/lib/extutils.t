#!./perl -w

print "1..10\n";

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

$| = 1;

my $dir = "ext-$$";
my @files;

print "# $dir being created...\n";
mkdir $dir, 0777 or die "mkdir: $!\n";

use File::Spec::Functions;

END {
    use File::Path;
    print "# $dir being removed...\n";
    rmtree($dir);
}

my @names = ("THREE", {name=>"OK4", type=>"PV",},
             {name=>"OK5", type=>"PVN",
              value=>['"not ok 5\\n\\0ok 5\\n"', 15]},
             {name => "FARTHING", type=>"NV"},
             {name => "NOT_ZERO", type=>"UV", value=>~0 . "u"});

my @names_only = map {(ref $_) ? $_->{name} : $_} @names;

my $package = "ExtTest";
################ Header
my $header = catfile($dir, "test.h");
push @files, "test.h";
open FH, ">$header" or die "open >$header: $!\n";
print FH <<'EOT';
#define THREE 3
#define OK4 "ok 4\n"
#define OK5 1
#define FARTHING 0.25
#define NOT_ZERO 1
EOT
close FH or die "close $header: $!\n";

################ XS
my $xs = catfile($dir, "$package.xs");
push @files, "$package.xs";
open FH, ">$xs" or die "open >$xs: $!\n";

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
close FH or die "close $xs: $!\n";

################ PM
my $pm = catfile($dir, "$package.pm");
push @files, "$package.pm";
open FH, ">$pm" or die "open >$pm: $!\n";
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
close FH or die "close $pm: $!\n";

################ test.pl
my $testpl = catfile($dir, "test.pl");
push @files, "test.pl";
open FH, ">$testpl" or die "open >$testpl: $!\n";

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

close FH or die "close $testpl: $!\n";

################ dummy Makefile.PL
# Keep the dependancy in the Makefile happy
my $makefilePL = catfile($dir, "Makefile.PL");
push @files, "Makefile.PL";
open FH, ">$makefilePL" or die "open >$makefilePL: $!\n";
close FH or die "close $makefilePL: $!\n";

chdir $dir or die $!; push @INC,  '../../lib';
END {chdir ".." or warn $!};

# Grr. MakeMaker hardwired to write its message to STDOUT.
print "# ";
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
push @files, "Makefile.old"; # Renamed by make clean

my $make = $Config{make};

$make = $ENV{MAKE} if exists $ENV{MAKE};

my $makeout;

print "# make = '$make'\n";
$makeout = `$make`;
if ($?) {
  print "not ok 2 # $make failed: $?\n";
  exit($?);
} else {
  print "ok 2\n";
}

my $maketest = "$make test";
print "# make = '$maketest'\n";
$makeout = `$maketest`;
if ($?) {
  print "not ok 8 # $make failed: $?\n";
} else {
  # Perl babblings
  $makeout =~ s/^\s*PERL_DL_NONLAZY=.+?\n//m;

  # GNU make babblings
  $makeout =~ s/^\w*?make.+?(?:entering|leaving) directory.+?\n//mig;

  print $makeout;
  print "ok 8\n";
}

my $makeclean = "$make clean";
print "# make = '$makeclean'\n";
$makeout = `$makeclean`;
if ($?) {
  print "not ok 9 # $make failed: $?\n";
} else {
  print "ok 9\n";
}

foreach (@files) {
  unlink $_ or warn "unlink $_: $!";
}

my $fail;
opendir DIR, "." or die "opendir '.': $!";
while (defined (my $entry = readdir DIR)) {
  next if $entry =~ /^\.\.?$/;
  print "# Extra file '$entry'\n";
  $fail = 1;
}
closedir DIR or warn "closedir '.': $!";
if ($fail) {
  print "not ok 10\n";
} else {
  print "ok 10\n";
}
