#!./perl

BEGIN {
    if ($^O eq 'MacOS') {
	@INC = qw(: ::lib ::macos:lib);
    }
}

$|  = 1;
use warnings;
use strict;
use Config;

print "1..1\n";

my $test = 1;

sub ok { print "ok $test\n"; $test++ }


my $a;
my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

my $path = join " ", map { qq["-I$_"] } @INC;
my $redir = $Is_MacOS ? "" : "2>&1";


chomp($a = `$^X $path "-MB::Stash" "-Mwarnings" -e1`);
$a = join ',', sort split /,/, $a;
$a =~ s/-u(PerlIO|open)(?:::\w+)?,//g if defined $Config{'useperlio'} and $Config{'useperlio'} eq 'define';
$a =~ s/-uWin32,// if $^O eq 'MSWin32';
$a =~ s/-u(Cwd|File|File::Copy|OS2),//g if $^O eq 'os2';
$a =~ s/-uCwd,// if $^O eq 'cygwin';
  $b = '-uCarp,-uCarp::Heavy,-uDB,-uExporter,-uExporter::Heavy,-uattributes,'
     . '-umain,-ustrict,-uutf8,-uwarnings';
if ($Is_VMS) {
    $a =~ s/-uFile,-uFile::Copy,//;
    $a =~ s/-uVMS,-uVMS::Filespec,//;
    $a =~ s/-uSocket,//; # Socket is optional/compiler version dependent
}
if ($Config{static_ext} eq ' ' ||
    ($Config{static_ext} eq 'Socket' && $Is_VMS)) {
  if (ord('A') == 193) { # EBCDIC sort order is qw(a A) not qw(A a)
      $b = join ',', sort split /,/, $b;
  }
  print "# [$a]\n# vs.\n# [$b]\nnot " if $a ne $b;
  ok;
} else {
  print "ok $test # skipped: one or more static extensions\n"; $test++;
}
