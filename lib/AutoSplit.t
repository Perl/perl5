#!./perl -w

# AutoLoader.t runs before this test, so it seems safe to assume that it will
# work.

my $incdir;
my $lib = '"-I../lib"'; # ok on unix, nt, The extra \" are for VMS
BEGIN {
    chdir 't' if -d 't';
    if ($^O eq 'MacOS') {
	$incdir = ":auto-$$";
        $lib = '-x -I::lib:'; # -x overcomes MPW $Config{startperl} anomaly
    } else {
	$incdir = "auto-$$";
    }
    @INC = $incdir;
    push @INC, '../lib';
}
my $runperl = "$^X $lib";

use warnings;
use strict;
use Test::More tests => 58;
use File::Spec;
use File::Find;

require AutoSplit; # Run time. Check it compiles.
ok (1, "AutoSplit loaded");

END {
    use File::Path;
    print "# $incdir being removed...\n";
    rmtree($incdir);
}

mkdir $incdir,0755;

my @tests;
{
  # local this else it buggers up the chomp() below.
  # Hmm. Would be nice to have this as a regexp.
  local $/
    = "################################################################\n";
  @tests = <DATA>;
  close DATA;
}

sub split_a_file {
  my $contents = shift;
  my $file = $_[0];
  if (defined $contents) {
    open FILE, ">$file" or die "Can't open $file: $!";
    print FILE $contents;
    close FILE or die "Can't close $file: $!";
  }

  # Assumption: no characters in arguments need escaping from the shell or perl
  my $com = qq($runperl -e "use AutoSplit; autosplit (qw(@_))");
  print "# $com\n";
  # There may be a way to capture STDOUT without spawning a child process, but
  # it's probably worthwhile spawning, as it ensures that nothing in AutoSplit
  # can load functions from split modules into this perl.
  my $output = `$com`;
  warn "Exit status $? from running: >>$com<<" if $?;
  return $output;
}

my $i = 0;
my $dir = File::Spec->catfile($incdir, 'auto');
foreach (@tests) {
  my $module = 'A' . $i . '_' . $$ . 'splittest';
  my $file = File::Spec->catfile($incdir,"$module.pm");
  s/\*INC\*/$incdir/gm;
  s/\*DIR\*/$dir/gm;
  s/\*MOD\*/$module/gm;
  # Build a hash for this test.
  my %args = /^\#\#\ ([^\n]*)\n	# Key is on a line starting ##
             ((?:[^\#]+		# Any number of characters not #
               | \#(?!\#)	# or a # character not followed by #
               | (?<!\n)\#	# or a # character not preceded by \n
              )*)/sgmx;
  foreach ($args{Name}, $args{Require}, $args{Extra}) {
    chomp $_ if defined $_;
  }
  my @extra_args = !defined $args{Extra} ? () : split /,/, $args{Extra};
  my ($output, $body);
  if ($args{File}) {
    $body ="package $module;\n" . $args{File};
    $output = split_a_file ($body, $file, $dir, @extra_args);
  } else {
    # Repeat tests
    $output = split_a_file (undef, $file, $dir, @extra_args);
  }

  # test n+1
  is ($output, $args{Get}, "Output from autosplit()ing $args{Name}");

  if ($args{Files}) {
    $args{Files} =~ s!/!:!gs if $^O eq 'MacOS';
    my (%missing, %got);
    find (sub {$got{$File::Find::name}++ unless -d $_}, $dir);
    foreach (split /\n/, $args{Files}) {
      next if /^#/;
      unless (delete $got{$_}) {
        $missing{$_}++;
      }
    }
    my @missing = keys %missing;
    # test n+2
    unless (ok (!@missing, "Are any expected files missing?")) {
      print "# These files are missing\n";
      print "# $_\n" foreach sort @missing;
    }
    my @extra = keys %got;
    # test n+3
    unless (ok (!@extra, "Are any extra files present?")) {
      print "# These files are unexpectedly present:\n";
      print "# $_\n" foreach sort @extra;
    }
  }
  if ($args{Require}) {
    my $com = 'require "' . File::Spec->catfile ('auto', $args{Require}) . '"';
    eval $com;
    # test n+3
    ok ($@ eq '', $com) or print "# \$\@ = '$@'\n";
    if (defined $body) {
      eval $body or die $@;
    }
  }
  # match tests to check for prototypes
  if ($args{Match}) {
    local $/;
    my $file = File::Spec->catfile($dir, $args{Require});
    open IX, $file or die "Can't open '$file': $!";
    my $ix = <IX>;
    close IX or die "Can't close '$file': $!";
    foreach my $pat (split /\n/, $args{Match}) {
      next if $pat =~ /^\#/;
      like ($ix, qr/^\s*$pat\s*$/m, "match $pat");
    }
  }
  # code tests contain eval{}ed ok()s etc
  if ($args{Tests}) {
    foreach my $code (split /\n/, $args{Tests}) {
      next if $code =~ /^\#/;
      defined eval $code or fail(), print "# Code:  $code\n# Error: $@";
    }
  }
  unless ($args{SameAgain}) {
    $i++;
    rmtree($dir);
    mkdir $dir, 0775;
  }
}

__DATA__
## Name
tests from the end of the AutoSplit module.
## File
use AutoLoader 'AUTOLOAD';
{package Just::Another;
 use AutoLoader 'AUTOLOAD';
}
@Yet::Another::AutoSplit::ISA = 'AutoLoader';
1;
__END__
sub test1 ($)   { "test 1"; }
sub test2 ($$)  { "test 2"; }
sub test3 ($$$) { "test 3"; }
sub testtesttesttest4_1  { "test 4"; }
sub testtesttesttest4_2  { "duplicate test 4"; }
sub Just::Another::test5 { "another test 5"; }
sub test6       { return join ":", __FILE__,__LINE__; }
package Yet::Another::AutoSplit;
sub testtesttesttest4_1 ($)  { "another test 4"; }
sub testtesttesttest4_2 ($$) { "another duplicate test 4"; }
package Yet::More::Attributes;
sub test_a1 ($) : locked :locked { 1; }
sub test_a2 : locked { 1; }
# And that was all it has. You were expected to manually inspect the output
## Get
Warning: AutoSplit had to create top-level *DIR* unexpectedly.
AutoSplitting *INC*/*MOD*.pm (*DIR*/*MOD*)
*INC*/*MOD*.pm: some names are not unique when truncated to 8 characters:
 directory *DIR*/*MOD*:
  testtesttesttest4_1.al, testtesttesttest4_2.al truncate to testtest
 directory *DIR*/Yet/Another/AutoSplit:
  testtesttesttest4_1.al, testtesttesttest4_2.al truncate to testtest
## Files
*DIR*/*MOD*/autosplit.ix
*DIR*/*MOD*/test1.al
*DIR*/*MOD*/test2.al
*DIR*/*MOD*/test3.al
*DIR*/*MOD*/testtesttesttest4_1.al
*DIR*/*MOD*/testtesttesttest4_2.al
*DIR*/Just/Another/test5.al
*DIR*/*MOD*/test6.al
*DIR*/Yet/Another/AutoSplit/testtesttesttest4_1.al
*DIR*/Yet/Another/AutoSplit/testtesttesttest4_2.al
*DIR*/Yet/More/Attributes/test_a1.al
*DIR*/Yet/More/Attributes/test_a2.al
## Require
*MOD*/autosplit.ix
## Match
# Need to find these lines somewhere in the required file
sub test1\s*\(\$\);
sub test2\s*\(\$\$\);
sub test3\s*\(\$\$\$\);
sub testtesttesttest4_1\s*\(\$\);
sub testtesttesttest4_2\s*\(\$\$\);
sub test_a1\s*\(\$\)\s*:\s*locked\s*:\s*locked\s*;
sub test_a2\s*:\s*locked\s*;
## Tests
is (*MOD*::test1 (1), 'test 1');
is (*MOD*::test2 (1,2), 'test 2');
is (*MOD*::test3 (1,2,3), 'test 3');
ok (!defined eval "*MOD*::test1 () eq 'test 1'" and $@ =~ /^Not enough arguments for *MOD*::test1/, "Check prototypes mismatch fails") or print "# \$\@='$@'";
is (&*MOD*::testtesttesttest4_1, "test 4");
is (&*MOD*::testtesttesttest4_2, "duplicate test 4");
is (&Just::Another::test5, "another test 5");
# very messy way to interpolate function into regexp, but it's going to be
# needed to get : for Mac filespecs
like (&*MOD*::test6, qr!^*INC*/*MOD*.pm \(autosplit into @{[File::Spec->catfile('*DIR*','*MOD*', 'test6.al')]}\):\d+$!);
ok (Yet::Another::AutoSplit->testtesttesttest4_1 eq "another test 4");
################################################################
## Name
missing use AutoLoader;
## File
1;
__END__
## Get
## Files
# There should be no files.
################################################################
## Name
missing use AutoLoader; (but don't skip)
## Extra
0, 0
## File
1;
__END__
## Get
AutoSplitting *INC*/*MOD*.pm (*DIR*/*MOD*)
## Require
*MOD*/autosplit.ix
## Files
*DIR*/*MOD*/autosplit.ix
################################################################
## Name
Split prior to checking whether obsolete files get deleted
## File
use AutoLoader 'AUTOLOAD';
1;
__END__
sub obsolete {my $a if 0; return $a++;}
sub gonner {warn "This gonner function should never get called"}
## Get
AutoSplitting *INC*/*MOD*.pm (*DIR*/*MOD*)
## Require
*MOD*/autosplit.ix
## Files
*DIR*/*MOD*/autosplit.ix
*DIR*/*MOD*/gonner.al
*DIR*/*MOD*/obsolete.al
## Tests
is (&*MOD*::obsolete, 0);
is (&*MOD*::obsolete, 1);
{my $time = time; print "# time is $time\n"; sleep (2); sleep (2) unless time > $time + 1}
printf "# time is %d (hopefully >=2 seconds later)\n", time;
## SameAgain
True, so don't scrub this directory.
Need the sleep hack else the next test is so fast that the timestamp compare
routine in AutoSplit thinks that it shouldn't split the files.
IIRC DOS FAT filesystems have only 2 second granularity.
################################################################
## Name
Check whether obsolete files get deleted
## File
use AutoLoader 'AUTOLOAD';
1;
__END__
sub skeleton {"bones"};
sub ghost {"scream"}; # This definition gets overwritten with the one below
sub ghoul {"wail"};
sub zombie {"You didn't use fire."};
sub flying_pig {"Oink oink flap flap"};
## Get
AutoSplitting *INC*/*MOD*.pm (*DIR*/*MOD*)
## Require
*MOD*/autosplit.ix
## Files
*DIR*/*MOD*/autosplit.ix
*DIR*/*MOD*/skeleton.al
*DIR*/*MOD*/zombie.al
*DIR*/*MOD*/ghost.al
*DIR*/*MOD*/ghoul.al
*DIR*/*MOD*/flying_pig.al
## Tests
is (&*MOD*::skeleton, "bones", "skeleton");
eval {&*MOD*::gonner}; ok ($@ =~ m!^Can't locate auto/*MOD*/gonner.al in \@INC!, "Check &*MOD*::gonner is now a gonner") or print "# \$\@='$@'\n";
{my $time = time; print "# time is $time\n"; sleep (2); sleep (2) unless time > $time + 1}
printf "# time is %d (hopefully >=2 seconds later)\n", time;
## SameAgain
True, so don't scrub this directory.
################################################################
## Name
Check whether obsolete files remain when keep is 1
## Extra
1, 1
## File
use AutoLoader 'AUTOLOAD';
1;
__END__
sub ghost {"bump"};
sub wraith {9};
## Get
AutoSplitting *INC*/*MOD*.pm (*DIR*/*MOD*)
## Require
*MOD*/autosplit.ix
## Files
*DIR*/*MOD*/autosplit.ix
*DIR*/*MOD*/skeleton.al
*DIR*/*MOD*/zombie.al
*DIR*/*MOD*/ghost.al
*DIR*/*MOD*/ghoul.al
*DIR*/*MOD*/wraith.al
*DIR*/*MOD*/flying_pig.al
## Tests
is (&*MOD*::ghost, "bump");
is (&*MOD*::zombie, "You didn't use fire.", "Are our zombies undead?");
{my $time = time; print "# time is $time\n"; sleep (2); sleep (2) unless time > $time + 1}
printf "# time is %d (hopefully >=2 seconds later)\n", time;
## SameAgain
True, so don't scrub this directory.
################################################################
## Name
Without the the timestamp check make sure that nothing happens
## Extra
0, 1, 1
## Require
*MOD*/autosplit.ix
## Files
*DIR*/*MOD*/autosplit.ix
*DIR*/*MOD*/skeleton.al
*DIR*/*MOD*/zombie.al
*DIR*/*MOD*/ghost.al
*DIR*/*MOD*/ghoul.al
*DIR*/*MOD*/wraith.al
*DIR*/*MOD*/flying_pig.al
## Tests
is (&*MOD*::ghoul, "wail", "still haunted");
is (&*MOD*::zombie, "You didn't use fire.", "Are our zombies still undead?");
{my $time = time; print "# time is $time\n"; sleep (2); sleep (2) unless time > $time + 1}
printf "# time is %d (hopefully >=2 seconds later)\n", time;
## SameAgain
True, so don't scrub this directory.
################################################################
## Name
With the the timestamp check make sure that things happen (stuff gets deleted)
## Extra
0, 1, 0
## Get
AutoSplitting *INC*/*MOD*.pm (*DIR*/*MOD*)
## Require
*MOD*/autosplit.ix
## Files
*DIR*/*MOD*/autosplit.ix
*DIR*/*MOD*/ghost.al
*DIR*/*MOD*/wraith.al
## Tests
is (&*MOD*::wraith, 9);
eval {&*MOD*::flying_pig}; ok ($@ =~ m!^Can't locate auto/*MOD*/flying_pig.al in \@INC!, "There are no flying pigs") or print "# \$\@='$@'\n";
