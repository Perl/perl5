use strict;
use Cwd;
use File::Path;
use File::Find;

my %opts = (
  #defaults
    'distdir' => 'distdir',
    'unicode' => 1, # include unicode by default
    'minimal' => 0, # minimal possible distribution.
                    # actually this is just perl.exe and perlXX.dll
		    # but can be extended by additional exts 
		    #  ... (as soon as this will be implemented :)
    'include-modules' => '', # TODO
    'exclude-modules' => '', # TODO
    #??? 'only-modules' => '', # TODO
    'platform' => 'wince',
    'strip-pod' => 0, # TODO strip POD from perl modules
    'adaptation' => 0, # TODO do some adaptation, such as stripping such
                       # occurences as "if ($^O eq 'VMS'){...}" for certain modules
    'zip' => 0,     # perform zip (TODO)
    'clean-exts' => 0,
  #options itself
    (map {/^--([\-_\w]+)=(.*)$/} @ARGV),                            # --opt=smth
    (map {/^no-?(.*)$/i?($1=>0):($_=>1)} map {/^--([\-_\w]+)$/} @ARGV),  # --opt --no-opt --noopt
  );

# TODO -- error checking. When something goes wrong, just exit with rc!=0

my $cwd = cwd;

if ($opts{'clean-exts'}) {
  # unfortunately, unlike perl58.dll and like, extensions for different
  # platforms are built in same directory, therefore we must be able to clean
  # them often
  unlink '../config.sh'; # delete cache config file, which remembers our previous config
  chdir '../ext';
  find({no_chdir=>1,wanted => sub{
        unlink if /((?:\.obj|\/makefile|\/errno\.pm))$/i;
      }
    },'.');
  exit;
}

my (%libexclusions, %extexclusions);
my @lfiles;
sub copy($$);

# lib
chdir '../lib';
find({no_chdir=>1,wanted=>sub{push @lfiles, $_ if /\.p[lm]$/}},'.');
chdir $cwd;
# exclusions
@lfiles = grep {!exists $libexclusions{$_}} @lfiles;
#inclusions
#...
#copy them
for (@lfiles) {
  /^(.*)\/[^\/]+$/;
  mkpath "$opts{distdir}/lib/$1";
  copy "../lib/$_", "$opts{distdir}/lib/$_";
}

#ext
my @efiles;
chdir '../ext';
find({no_chdir=>1,wanted=>sub{push @efiles, $_ if /\.pm$/}},'.');
chdir $cwd;
# exclusions
#...
#inclusions
#...
#copy them
#{s[/(\w+)/\1\.pm][/$1.pm]} @efiles;
for (@efiles) {
  /^(.*)\/([^\/]+)\/([^\/]+)$/;
  copy "../ext/$_", "$opts{distdir}/lib/$1/$3";
}

# Config.pm
copy "../xlib/$opts{platform}/Config.pm", "$opts{distdir}/lib/Config.pm";

# auto
my @afiles;
chdir "../xlib/$opts{platform}/auto";
find({no_chdir=>1,wanted=>sub{push @afiles, $_ if /\.(dll|bs)$/}},'.');
chdir $cwd;
for (@afiles) {
  copy "../xlib/$opts{platform}/auto/$_", "$opts{distdir}/lib/auto/$_";
}

sub copy {
  my ($fnfrom, $fnto) = @_;
  my $ffrom = do {local (@ARGV,$/) = $fnfrom; <>};
  if ($opts{'strip-pod'}) {
    # actually following regexp is suspicious to not work everywhere.
    # but we've checked on our set of modules, and it's fit for our purposes
    $ffrom =~ s/^=\w+.*?^=cut(?:\n|\Z)//msg;
    # $ffrom =~ s/^__END__.*\Z//msg; # TODO -- deal with Autoload
  }
  mkpath $1 if $fnto=~/^(.*)\/([^\/]+)$/;
  open my $fhout, ">$fnto";
  print $fhout $ffrom;
}

BEGIN {
%libexclusions = map {$_=>1} split/\s/, <<"EOS";
abbrev.pl bigfloat.pl bigint.pl bigrat.pl cacheout.pl complete.pl ctime.pl
dotsh.pl exceptions.pl fastcwd.pl flush.pl ftp.pl getcwd.pl getopt.pl
getopts.pl hostname.pl look.pl newgetopt.pl pwd.pl termcap.pl
EOS
%extexclusions = map {$_=>1} split/\s/, <<"EOS";
EOS

}

