=comments

helper script to make life for PerlCE easier.

You need edit values for @defs array to reflect your changes and then do

  perl comp.pl [any-additional-options]

This will call
  nmake -f Makefile.ce
with most parameters overrided as you specified and additional options
(such as build target) will also be prepended to command line to execute.

There are also additional different modes for running this script:
  perl comp.pl --run [any-command-line-arguments]
and
  perl comp.pl --do [any-command-line-arguments]
and
  perl comp.pl --copy-pm pc:[pc-location] ce:[ce-location]

--run executes this build of perl on CE device with arguments provided
--run=test will display a predefined messagebox that say everything is ok.

--do  Executes on local computer command that is presented by arguments
      immediately following after --do
      Most reason why you may want to execute script in this mode is that
      arguments preprocessed to replace [p] occurences into current perl
      location. Typically it is handy to run
  perl comp.pl --do cecopy pc:..\lib\Exporter.pm ce:[p]\lib

--copy copies file to CE device
  here also [p] will be expanded to corrent PerlCE path, and additionally
  when --copy=compact specified then, if filename looks like perl module,
  then POD will be stripped away from that file
  modules


=cut

use Cwd;
use strict;

# edit value of $inst_root variable to reflect your desired location of
# built perl
my $inst_root = "\\Storage Card\\perl-tests\\perl\@16225";
my @defs = (
  "\"PV=\"",
  "\"INST_VER=\"",
  "\"INSTALL_ROOT=$inst_root\"",
  "\"WCEROOT=$ENV{SDKROOT}\"",
  "NTPERL=$^X", #todo: check version: this must be (almost?) current version
  "\"CEPATH=$ENV{WCEROOT}\"",
  "CELIBDLLDIR=d:\\personal\\pocketPC\\celib-palm-3.0",
  "CECONSOLEDIR=d:\\personal\\pocketPC\\w32console",
  "YES=/y",
  "CFG=RELEASE",
  "MACHINE=wince-mips-pocket-wce300",
  "PERLCEDIR=".cwd,
  #NIY "\"CECOPY=\$(NTPERL) \$(PERLCEDIR)\\$0 --copy=compact\"",
  "\"CECOPY=\$(NTPERL) \$(PERLCEDIR)\\$0 --copy\"",
);

my %opts = (
  # %known_opts enumerates allowed opts as well as specifies default
  #   and initial values
  my %known_opts = (
     'do' => '',
     'run' => '',
     'copy' => '',
  ),
  #options itself
  my %specified_opts = (
    (map {/^--([\-_\w]+)=(.*)$/} @ARGV),                            # --opt=smth
    (map {/^no-?(.*)$/i?($1=>0):($_=>1)} map {/^--([\-_\w]+)$/} @ARGV),  # --opt --no-opt --noopt
  ),
);
die "option '$_' is not recognized" for grep {!exists $known_opts{$_}} keys %specified_opts;
@ARGV = grep {!/^--/} @ARGV;

if ($opts{'do'}) {
  s/\[p\]/$inst_root/g for @ARGV;
  system(@ARGV);
}
elsif ($opts{'run'}) {
  if ($opts{'run'} eq 'test') {
    system("ceexec","$inst_root\\bin\\perl","-we","Win32::MessageBox(\$].qq(\n).join'','cc'..'dx')");
  }
  else {
    system("ceexec","$inst_root\\bin\\perl", map {/^".*"$/s?$_:"\"$_\""} @ARGV);
  }
}
elsif ($opts{'copy'}) {
  if ($opts{'copy'} eq 'compact') {
    die "todo";
  }
  s/\[p\]/$inst_root/g for @ARGV;
  if ($ARGV[0]=~/^pc:/i) {system("cedel",$ARGV[1])}
  system("cecopy",@ARGV);
}
else {
  my $cmd = "nmake -f Makefile.ce @defs @ARGV";
  print $cmd;
  system($cmd);
}


=comments

  Author Vadim Konovalov.

=cut
