#!./perl -w

print "1..27\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use warnings;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Constant qw (constant_types C_constant XS_constant autoload);
use Config;
use File::Spec::Functions;
use File::Spec;
# Because were are going to be changing directory before running Makefile.PL
my $perl = File::Spec->rel2abs( $^X );
# ExtUtils::Constant::C_constant uses $^X inside a comment, and we want to
# compare output to ensure that it is the same. We were probably run as ./perl
# whereas we will run the child with the full path in $perl. So make $^X for
# us the same as our child will see.
$^X = $perl;

print "# perl=$perl\n";
my $runperl = "$perl -x \"-I../../lib\"";

$| = 1;

my $dir = "ext-$$";
my @files;

print "# $dir being created...\n";
mkdir $dir, 0777 or die "mkdir: $!\n";


END {
    use File::Path;
    print "# $dir being removed...\n";
    rmtree($dir);
}

my $package = "ExtTest";

# Test the code that generates 1 and 2 letter name comparisons.
my %compass = (
N => 0, NE => 45, E => 90, SE => 135, S => 180, SW => 225, W => 270, NW => 315
);

my $parent_rfc1149 =
  'A Standard for the Transmission of IP Datagrams on Avian Carriers';

my @names = ("FIVE", {name=>"OK6", type=>"PV",},
             {name=>"OK7", type=>"PVN",
              value=>['"not ok 7\\n\\0ok 7\\n"', 15]},
             {name => "FARTHING", type=>"NV"},
             {name => "NOT_ZERO", type=>"UV", value=>"~(UV)0"},
             {name => "OPEN", type=>"PV", value=>'"/*"', macro=>1},
             {name => "CLOSE", type=>"PV", value=>'"*/"',
              macro=>["#if 1\n", "#endif\n"]},
             {name => "ANSWER", default=>["UV", 42]}, "NOTDEF",
             {name => "Yes", type=>"YES"},
             {name => "No", type=>"NO"},
             {name => "Undef", type=>"UNDEF"},
# OK. It wasn't really designed to allow the creation of dual valued constants.
# It was more for INADDR_ANY INADDR_BROADCAST INADDR_LOOPBACK INADDR_NONE
             {name=>"RFC1149", type=>"SV", value=>"sv_2mortal(temp_sv)",
              pre=>"SV *temp_sv = newSVpv(RFC1149, 0); "
              	   . "(void) SvUPGRADE(temp_sv,SVt_PVIV); SvIOK_on(temp_sv); "
                   . "SvIVX(temp_sv) = 1149;"},
);

push @names, $_ foreach keys %compass;

my @names_only = map {(ref $_) ? $_->{name} : $_} @names;

my $types = {};
my $constant_types = constant_types(); # macro defs
my $C_constant = join "\n",
  C_constant ($package, undef, "IV", $types, undef, undef, @names);
my $XS_constant = XS_constant ($package, $types); # XS for ExtTest::constant

################ Header
my $header = catfile($dir, "test.h");
push @files, "test.h";
open FH, ">$header" or die "open >$header: $!\n";
print FH <<"EOT";
#define FIVE 5
#define OK6 "ok 6\\n"
#define OK7 1
#define FARTHING 0.25
#define NOT_ZERO 1
#define Yes 0
#define No 1
#define Undef 1
#define RFC1149 "$parent_rfc1149"
#undef NOTDEF

EOT

while (my ($point, $bearing) = each %compass) {
  print FH "#define $point $bearing\n"
}
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
print FH $constant_types;
print FH $C_constant, "\n";
print FH "MODULE = $package		PACKAGE = $package\n";
print FH "PROTOTYPES: ENABLE\n";
print FH $XS_constant;
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

print FH "use strict;\n";
print FH "use $package qw(@names_only);\n";
print FH <<'EOT';

# IV
my $five = FIVE;
if ($five == 5) {
  print "ok 5\n";
} else {
  print "not ok 5 # $five\n";
}

# PV
print OK6;

# PVN containing embedded \0s
$_ = OK7;
s/.*\0//s;
print;

# NV
my $farthing = FARTHING;
if ($farthing == 0.25) {
  print "ok 8\n";
} else {
  print "not ok 8 # $farthing\n";
}

# UV
my $not_zero = NOT_ZERO;
if ($not_zero > 0 && $not_zero == ~0) {
  print "ok 9\n";
} else {
  print "not ok 9 # \$not_zero=$not_zero ~0=" . (~0) . "\n";
}

# Value includes a "*/" in an attempt to bust out of a C comment.
# Also tests custom cpp #if clauses
my $close = CLOSE;
if ($close eq '*/') {
  print "ok 10\n";
} else {
  print "not ok 10 # \$close='$close'\n";
}

# Default values if macro not defined.
my $answer = ANSWER;
if ($answer == 42) {
  print "ok 11\n";
} else {
  print "not ok 11 # What do you get if you multiply six by nine? '$answer'\n";
}

# not defined macro
my $notdef = eval { NOTDEF; };
if (defined $notdef) {
  print "not ok 12 # \$notdef='$notdef'\n";
} elsif ($@ !~ /Your vendor has not defined ExtTest macro NOTDEF/) {
  print "not ok 12 # \$@='$@'\n";
} else {
  print "ok 12\n";
}

# not a macro
my $notthere = eval { &ExtTest::NOTTHERE; };
if (defined $notthere) {
  print "not ok 13 # \$notthere='$notthere'\n";
} elsif ($@ !~ /NOTTHERE is not a valid ExtTest macro/) {
  chomp $@;
  print "not ok 13 # \$@='$@'\n";
} else {
  print "ok 13\n";
}

# Truth
my $yes = Yes;
if ($yes) {
  print "ok 14\n";
} else {
  print "not ok 14 # $yes='\$yes'\n";
}

# Falsehood
my $no = No;
if (defined $no and !$no) {
  print "ok 15\n";
} else {
  print "not ok 15 # \$no=" . defined ($no) ? "'$no'\n" : "undef\n";
}

# Undef
my $undef = Undef;
unless (defined $undef) {
  print "ok 16\n";
} else {
  print "not ok 16 # \$undef='$undef'\n";
}


# invalid macro (chosen to look like a mix up between No and SW)
$notdef = eval { &ExtTest::So };
if (defined $notdef) {
  print "not ok 17 # \$notdef='$notdef'\n";
} elsif ($@ !~ /^So is not a valid ExtTest macro/) {
  print "not ok 17 # \$@='$@'\n";
} else {
  print "ok 17\n";
}

# invalid defined macro
$notdef = eval { &ExtTest::EW };
if (defined $notdef) {
  print "not ok 18 # \$notdef='$notdef'\n";
} elsif ($@ !~ /^EW is not a valid ExtTest macro/) {
  print "not ok 18 # \$@='$@'\n";
} else {
  print "ok 18\n";
}

my %compass = (
EOT

while (my ($point, $bearing) = each %compass) {
  print FH "$point => $bearing, "
}

print FH <<'EOT';

);

my $fail;
while (my ($point, $bearing) = each %compass) {
  my $val = eval $point;
  if ($@) {
    print "# $point: \$@='$@'\n";
    $fail = 1;
  } elsif (!defined $bearing) {
    print "# $point: \$val=undef\n";
    $fail = 1;
  } elsif ($val != $bearing) {
    print "# $point: \$val=$val, not $bearing\n";
    $fail = 1;
  }
}
if ($fail) {
  print "not ok 19\n";
} else {
  print "ok 19\n";
}

EOT

print FH <<"EOT";
my \$rfc1149 = RFC1149;
if (\$rfc1149 ne "$parent_rfc1149") {
  print "not ok 20 # '\$rfc1149' ne '$parent_rfc1149'\n";
} else {
  print "ok 20\n";
}

if (\$rfc1149 != 1149) {
  printf "not ok 21 # %d != 1149\n", \$rfc1149;
} else {
  print "ok 21\n";
}

EOT

print FH <<'EOT';
# test macro=>1
my $open = OPEN;
if ($open eq '/*') {
  print "ok 22\n";
} else {
  print "not ok 22 # \$open='$open'\n";
}
EOT
close FH or die "close $testpl: $!\n";

################ Makefile.PL
# We really need a Makefile.PL because make test for a no dynamic linking perl
# will run Makefile.PL again as part of the "make perl" target.
my $makefilePL = catfile($dir, "Makefile.PL");
push @files, "Makefile.PL";
open FH, ">$makefilePL" or die "open >$makefilePL: $!\n";
print FH <<"EOT";
#!$perl -w
use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> "$package",
              'VERSION_FROM'	=> "$package.pm", # finds \$VERSION
              (\$] >= 5.005 ?
               (#ABSTRACT_FROM => "$package.pm", # XXX add this
                AUTHOR     => "$0") : ())
             );
EOT

close FH or die "close $makefilePL: $!\n";

chdir $dir or die $!; push @INC,  '../../lib';
END {chdir ".." or warn $!};

my @perlout = `$runperl Makefile.PL`;
if ($?) {
  print "not ok 1 # $runperl Makefile.PL failed: $?\n";
  print "# $_" foreach @perlout;
  exit($?);
} else {
  print "ok 1\n";
}


my $makefile = ($^O eq 'VMS' ? 'descrip' : 'Makefile');
my $makefile_ext = ($^O eq 'VMS' ? '.mms' : '');
if (-f "$makefile$makefile_ext") {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}
my $makefile_rename = ($^O eq 'VMS' ? '.mms' : '.old');
push @files, "$makefile$makefile_rename"; # Renamed by make clean

my $make = $Config{make};

$make = $ENV{MAKE} if exists $ENV{MAKE};

if ($^O eq 'MSWin32' && $make eq 'nmake') { $make .= " -nologo"; }

my $makeout;

print "# make = '$make'\n";
$makeout = `$make`;
if ($?) {
  print "not ok 3 # $make failed: $?\n";
  exit($?);
} else {
  print "ok 3\n";
}

if ($Config{usedl}) {
  print "ok 4\n";
} else {
  push @files, "perl$Config{exe_ext}";
  my $makeperl = "$make perl";
  print "# make = '$makeperl'\n";
  $makeout = `$makeperl`;
  if ($?) {
    print "not ok 4 # $makeperl failed: $?\n";
    exit($?);
  } else {
    print "ok 4\n";
  }
}

my $test = 23;
my $maketest = "$make test";
print "# make = '$maketest'\n";
$makeout = `$maketest`;

# echo of running the test script
$makeout =~ s/^\s*PERL_DL_NONLAZY=.+?\n//m;
$makeout =~ s/^MCR.+test.pl\n//mig if $^O eq 'VMS';

# GNU make babblings
$makeout =~ s/^\w*?make.+?(?:entering|leaving) directory.+?\n//mig;

# Hopefully gets most make's babblings
# make -f Makefile.aperl perl
$makeout =~ s/^\w*?make.+\sperl[^A-Za-z0-9]*\n//mig;
# make[1]: `perl' is up to date.
$makeout =~ s/^\w*?make.+perl.+?is up to date.*?\n//mig;

print $makeout;

if ($?) {
  print "not ok $test # $maketest failed: $?\n";
} else {
  print "ok $test\n";
}
$test++;

my $regen = `$runperl $package.xs`;
if ($?) {
  print "not ok $test # $runperl $package.xs failed: $?\n";
} else {
  print "ok $test\n";
}
$test++;

my $expect = $constant_types . $C_constant .
  "\n#### XS Section:\n" . $XS_constant;

if ($expect eq $regen) {
  print "ok $test\n";
} else {
  print "not ok $test\n";
  # open FOO, ">expect"; print FOO $expect;
  # open FOO, ">regen"; print FOO $regen; close FOO;
}
$test++;

my $makeclean = "$make clean";
print "# make = '$makeclean'\n";
$makeout = `$makeclean`;
if ($?) {
  print "not ok $test # $make failed: $?\n";
} else {
  print "ok $test\n";
}
$test++;

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
  print "not ok $test\n";
} else {
  print "ok $test\n";
}
