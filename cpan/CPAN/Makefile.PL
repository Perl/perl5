#!/usr/bin/perl -w -*- mode: cperl -*-
use strict;
use vars qw( $VERSION @ST_PREFS );
BEGIN {$CPAN::Config_loaded=1}
BEGIN {$CPAN::Config_loaded=1} # keep old perls with -w quiet
use ExtUtils::MakeMaker qw(:DEFAULT);
use File::Path;
eval { require File::Spec; };
my $HAVE_FILE_SPEC = !$@;
eval { require YAML::Syck; };
my $HAVE_YAML_SYCK = !$@;
use File::Basename qw(basename);
require Config;
my $HAVE_MAKE = basename($Config::Config{make}) eq "make"; # file-scoped!

# storable pref files
@ST_PREFS = qw(
              );


my $Id = q$Id: Makefile.PL 146 2005-08-09 04:25:21Z k $;
$VERSION = sprintf "%.3f", 1 + substr(q$Rev: 146 $,4)/1000;

my $version_diff = 0; # we'll have to die if this becomes true
my $version_from;
{
  local $^W;
  $ExtUtils::MakeMaker::VERSION = eval $ExtUtils::MakeMaker::VERSION;
}
if ($HAVE_FILE_SPEC) {
  $version_from = File::Spec->catfile(qw(lib CPAN.pm));
  my $version_set_manually = 1; # not by SVN

  if ($ARGV[0] && $ARGV[0] eq "--setversion") {
    die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.008;
    die "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nDo not make a release with it\n"
        if $ExtUtils::MakeMaker::VERSION < 6.4502;
    die "Your MakeMaker doesn't do the sign woodoo" unless
        MM->can("signature_target");
    shift @ARGV;
    my $st;
    local $ENV{LANG} = "C";
    my $dirty = ! system "git status -a > /dev/null";
    die "Not everything checked in or out?" if $dirty;

    if ($version_set_manually) {
      # we must control that the VERSION in CPAN.pm is the same as in the Makefile
      unshift @INC, "lib";
      require $version_from;
      open my $fh, "make the-release-name|" or die;
      my $have_version;
      while (<$fh>) {
        next unless /^version\s+([\d\._]+)/;
        $have_version = eval $1;
      }
      die "could not determine current version from Makefile" unless $have_version;
      eval q{
      no warnings "numeric";
      if ($CPAN::VERSION != $have_version) {
        warn "Not equal: CPAN::VERSION[$CPAN::VERSION] Makefile version[$have_version]";
        $version_diff = 1;
      }
};
      die $@ if $@;
    }
    exit unless $version_diff;
  }
}

# for 5.004_05 I installed all of them manually despite errors;
# version hints as of 2006-02
my $prereq_pm = {
                 'File::Spec' => 0,   # KWILLIAMS; requires
                                      # Scalar::Util;
                                      # PathTools-3.16.tar.gz
                 'File::Temp' => 0,   # TJENNESS; requires Test::More;
                 'Net::Ping' => 0,    # SMPETERS;
                 'Scalar::Util' => 0, # GBARR;
                                      # Scalar-List-Utils-1.18.tar.gz;
                 'Test::Harness' => 2.62,
                 'Test::More' => 0,   # MSCHWERN;
                                      # Test-Simple-0.62.tar.gz;
                };
if ($^O eq "darwin") {
  $prereq_pm->{'File::HomeDir'} = 0.69;
}

# if they have one of these we declare it as prereq for better reporting
for my $interesting_module (qw(
        Archive::Tar
        Archive::Zip
        CPAN::Checksums
        Compress::Zlib
        Data::Dumper
        Digest::SHA
        ExtUtils::CBuilder
        File::Copy
        File::HomeDir
        File::Spec
        File::Temp
        File::Which
        IO::Compress::Base
        IO::Zlib
        Module::Build
        Net::FTP
        Parse::CPAN::Meta
        Scalar::Util
        Term::ReadKey
        Term::ReadLine::Perl
        Test::More
        Text::Glob
        Text::ParseWords
        Text::Wrap
        YAML
        YAML::Syck
        YAML::XS
                             )) {
    eval "require $interesting_module";
    if (!$@) {
        $prereq_pm->{$interesting_module} ||= 0;
    }
}
if ($HAVE_FILE_SPEC) {
  # import PAUSE public key to user's keychain
  require Config;
  my $dir;
  for $dir (split /$Config::Config{path_sep}/, $ENV{PATH}) {
    my $abs = File::Spec->catfile($dir, 'gpg');
    my $cmd;
    if ($cmd = MM->maybe_command($abs)) {
      print "Importing PAUSE public key into your GnuPG keychain... ";
      system($cmd, '--quiet', '--import', <PAUSE*.pub>);
      print "done!\n";
      print "(You may wish to trust it locally with 'gpg --lsign-key 450F89EC')\n";
      last;
    }
  }
}

if ($HAVE_FILE_SPEC) {
    my $have_distroprefs = -d "distroprefs";
    my $have_notinchecksums = -f File::Spec->catdir("t","CPAN","authors","id","A","AN","ANDK","NotInChecksums-0.000.tar.gz");
    if ($have_distroprefs && !$have_notinchecksums) {
        warn <<EOW;

####-Note-for-repository-users-####
Please try
  make testdistros
before running 'make test'
It builds various missing pieces
####-Note-for-repository-users-####

EOW
    }
}
my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());
# warn "sign[@sign]";
WriteMakefile(
              INSTALLDIRS  => 'perl',  # as it is coming with perl
              NAME         => 'CPAN',
              VERSION_FROM => $version_from,
              EXE_FILES    => [qw(scripts/cpan)],
              PREREQ_PM    => $prereq_pm,
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
               (LICENSE      => "perl") : (),
              ),
              ($ExtUtils::MakeMaker::VERSION >= 6.48 ?
               (MIN_PERL_VERSION => '5.004') : (),
              ),
              clean        => {
                               FILES => "lib/CPAN/Config.pm t/dot-cpan/FTPstats.yml",
                              },
              @sign,
              ($] >= 5.005 ?
               (
                ABSTRACT_FROM  => 'lib/CPAN.pm', # retrieve abstract from module
                AUTHOR         => 'Andreas Koenig <andreas.koenig.gmwojprw@franz.ak.mind.de>') : (),
              ),
              dist => {
                       DIST_DEFAULT => join(" ", # note: order matters!
                                            "verify-no-subdir",
                                            "verify-changes-date",
                                            "verify-changes-version",
                                            "kwalify-distroprefs",
                                            "Makefile",
                                            "no_CR",
                                            "META.yml",
                                            "setversion",
                                            "README",
                                            "testdistros",
                                            "all",
                                            "tardist",
                                           ),
                       COMPRESS => 'gzip -9',
                      },
              # I took it from RT-CPAN ticket 30098:
              ($ExtUtils::MakeMaker::VERSION >= 6.4502 ?
               (META_ADD => {
                             resources => {
                                 repository => "git://github.com/andk/cpanpm.git",
                             },
                             keywords => ['CPAN','module','module installation'],
                            }) : ()),
             );

if ($version_diff){
  die "
==> I had to update some \$VERSIONs <==
==> Your Makefile has been rebuilt. <==
==> Please rerun the make command.  <==
";
}

package MY;

sub macro {
    q{
LC_ALL_noexport=en_GB.utf8

YAML_MODULE=YAML::Syck
}
}

sub postamble {
  return "" unless $HAVE_MAKE; # dmake has unknown issues with my Makefile
  my @m;
  push @m, q{
.SUFFIXES: .rnc .rng

.rnc.rng:
	trang -I rnc -O rng $*.rnc $*.rng

update: dd-prefs

# the subdirs on MY OWN BOX are allowed here (only used for make dist!)
OKDIRS=CPAN|DIST|bin|blib|cover_db|\
       distroprefs|eg|inc|lib|logs|patches|perlbug|\
       protocols|related|release-lib|scripts|t|talks

verify-no-subdir:
	@$(PERL) -e 'my$$s=join",",grep{!/^($(OKDIRS))\z/x&&-d($$_)}glob"*";' \
		-e 'die"unexpected dir:$$s"if$$s'

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^$$t\s/; END{die "Alert: did not find <$$t> in Changes file" unless $$ok}' Changes

verify-changes-version:
	@$(PERL) -ne '$$ok++,exit if /\b$(VERSION)\b/; END{die "Alert: did not find <$(VERSION)> in Changes file" unless $$ok}' Changes

kwalify-distroprefs:
	`echo $(PERL) | sed -e 's/perl$$/slaymake/'` validate

setversion:
	$(PERL) Makefile.PL --setversion

README: lib/CPAN.pm Makefile
	-[ -r $@ ] && chmod +w $@
	-$(PERL) -MPod::Text -e 'Pod::Text->new->parse_from_file(\*ARGV)' lib/CPAN.pm > $@

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release :: disttest
	git tag -m 'This is $(VERSION)' "$(VERSION)"
	ls -l $(DISTVNAME).tar$(SUFFIX)
	rm -rf $(DISTVNAME)
	$(NOECHO) $(ECHO) '%   lftp pause.perl.org'
	$(NOECHO) $(ECHO) '>   cd incoming'
	$(NOECHO) $(ECHO) '>   put $(DISTVNAME).tar$(SUFFIX)'
	$(NOECHO) $(ECHO) '>   quit'
	$(NOECHO) $(ECHO) '%   git push --tags master'

snapshot : Makefile no_CR META.yml README testdistros all tardist

# 16=Distribution; 32=Bundle; 32768=Queue
depefails:
	$(PERL) -Ilib -MCPAN -e 'CPAN::HandleConfig->load;$$CPAN::DEBUG|=16;$$CPAN::DEBUG|=32;$$CPAN::DEBUG|=32768;install(qw(CPAN::Test::Dummy::Perl5::Build::DepeFails));'

logs/.exists :
	mkdir -p logs
	touch $@

run :
	$(PERL) -Ilib -MCPAN -eshell

run_testenv_db :
	$(PERL) -Ilib -It -MCPAN::MyConfig -MCPAN -deshell

record-session :
	$(PERL) -Ilib -MCPAN -e '$$CPAN::Suppress_readline=$$CPAN::Echo_readline=1;shell' | tee ttt.out

run-with-sqlite :
	$(PERL) -I$$HOME/.cpan -Ilib -MCPAN::SQLite -MCPAN::MyConfig -MCPAN -e '$$CPAN::Config->{use_sqlite}++; $$CPAN::Config->{sqlite_dbname}="cpandb-sqlite"; shell'

testrun_very_offline : rm_mirrored_by run_emu_offline

testrun_emu_offline :
	$(PERL) -I$$HOME/.cpan -Ilib -MCPAN::MyConfig -MCPAN -e '@CPAN::Defaultsites = qw(file:///dev/null); $$CPAN::Config->{urllist} = []; shell'

rm_mirrored_by :
	rm -f $$HOME/.cpan/sources/MIRRORED.BY*

testrun_http_only :
	$(PERL) -I$$HOME/.cpan -Ilib -MCPAN::MyConfig -MCPAN -e '$$CPAN::Config->{urllist} = [qw(http://www.planet-elektronik.de/CPAN/)]; shell'

urllist :
	$(PERL) -Ilib -MCPAN -MCPAN::FirstTime -e 'CPAN::FirstTime::init("$$ENV{HOME}/.cpan/CPAN/MyConfig", args => [qw(urllist)])'

runadmin :
	$(PERL) -Ilib -MCPAN::Admin -eshell

rundb :
	$(PERL) -Ilib -MCPAN -deshell

sign:
	cpansign -s

show-batch-signing-keys:
	for f in PAUSE*.pub; do echo "++++$$f++++"; gpg --verbose --with-colons $$f; done

show-imported:
	gpg --list-sigs --with-colons 450F89EC

# seems to need at least gnupg 1.4.2:
upload-batch-signing-key:
	gpg --send-key 450F89EC

howto-release:
	@$(ECHO) make ci dist \&\& make release

META.yml: metafile
	$(CP) $(DISTVNAME)/META.yml  ./META.yml

install-devel-cover-unless-uptodate:
	$(PERL) -Ilib -MCPAN -e 'CPAN::Shell->install("/home/src/perl/devel-cover/SVN/.") unless CPAN::Shell->expand("Module","Devel::Cover")->uptodate'

install-devel-cover-unconditionally:
	$(PERL) -Ilib -MCPAN -e 'CPAN::Shell->install("/home/src/perl/devel-cover/SVN/.")'

testcover: testdistros install-devel-cover-unless-uptodate
	:>SIGNATURE
	$(PERL) -MDevel::Cover -e 0
	`dirname $(PERL)`/cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test
	`dirname $(PERL)`/cover

man:
	$(PERL)doc -F lib/CPAN.pm

testdistros: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-1.03.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails-1.02.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails-1.03.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake-1.02.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-1.05.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne-1.00.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo-1.00.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree-1.00.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq-1.00.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect-1.00.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Failearly-1.02.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features-1.06.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq-1.00.tar.gz \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip-1.03.zip \
        t/CPAN/authors/id/A/AN/ANDK/NotInChecksums-0.000.tar.gz

# sorry, unix centric (and only makes sense on a working copy of the
# repository; else 'make test TEST_FILES=t/30shell.t TEST_VERBOSE=1'
# will do)
testshell-with-protocol: testdistros
	$(PERL) -e 'for ("protocols"){-d $$_ or mkdir $$_, 0755}'
	$(MAKE) test TEST_FILES=t/30shell.t TEST_VERBOSE=1 PERL='$(PERL)' | \
		tee protocols/make-test-`date +%Y%m%dT%H%M%S`
	ls -lt protocols | head

testshell-with-protocol-without-expect: testdistros
	$(PERL) -e 'for ("protocols"){-d $$_ or mkdir $$_, 0755}'
	CPAN_RUN_SHELL_TEST_WITHOUT_EXPECT=1 $(MAKE) test \
		TEST_FILES=t/30shell.t TEST_VERBOSE=1 | \
		tee protocols/make-test-`date +%Y%m%dT%H%M%S`
	ls -lt protocols | head

testshell-with-protocol-twice: testdistros
	$(PERL) -e 'for ("protocols"){-d $$_ or mkdir $$_, 0755}'
	$(PERL) -p -i~ -e 's/colorize_output\D+\d/colorize_output=>0/' t/CPAN/TestConfig.pm
	$(MAKE) test TEST_FILES=t/30shell.t TEST_VERBOSE=1 | \
		tee protocols/make-test-`date +%Y%m%dT%H%M%S`
	$(PERL) -p -i~ -e 's/colorize_output\D+\d/colorize_output=>1/' t/CPAN/TestConfig.pm
	$(MAKE) test TEST_FILES=t/30shell.t TEST_VERBOSE=1 | \
		tee protocols/make-test-`date +%Y%m%dT%H%M%S`
	$(PERL) -p -i~ -e 's/colorize_output\D+\d/colorize_output=>0/' t/CPAN/TestConfig.pm
	ls -ltr protocols | tail

#
# testdistros
#

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-1.03.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build/Build.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build/lib/CPAN/Test/Dummy/Perl5/Build.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build && \
		$(PERL) Build.PL && \
		./Build dist && \
		mv CPAN-Test-Dummy-Perl5-Build-1.03.tar.gz .. && \
		./Build clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails-1.02.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails/README \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails/Build.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails/lib/CPAN/Test/Dummy/Perl5/Build/DepeFails.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-DepeFails && \
		$(PERL) Build.PL && \
		./Build dist && \
		mv CPAN-Test-Dummy-Perl5-Build-DepeFails-1.02.tar.gz .. && \
		./Build clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails-1.03.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails/README \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails/Build.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails/lib/CPAN/Test/Dummy/Perl5/Build/Fails.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Build-Fails && \
		$(PERL) Build.PL && \
		./Build dist && \
		mv CPAN-Test-Dummy-Perl5-Build-Fails-1.03.tar.gz .. && \
		./Build clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake-1.02.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake/Build.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake/lib/CPAN/Test/Dummy/Perl5/BuildOrMake.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-BuildOrMake && \
		$(PERL) Build.PL && \
		./Build dist && \
		mv CPAN-Test-Dummy-Perl5-BuildOrMake-1.02.tar.gz .. && \
		./Build clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-1.05.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make/lib/Bundle/CpanTestDummies.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make/lib/CPAN/Test/Dummy/Perl5/Make.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-1.05.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne-1.00.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne/lib/CPAN/Test/Dummy/Perl5/Make/CircDepeOne.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeOne && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-CircDepeOne-1.00.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo-1.00.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo/lib/CPAN/Test/Dummy/Perl5/Make/CircDepeTwo.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeTwo && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-CircDepeTwo-1.00.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree-1.00.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree/lib/CPAN/Test/Dummy/Perl5/Make/CircDepeThree.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-CircDepeThree && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-CircDepeThree-1.00.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq-1.00.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq/mymeta.yml \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq/lib/CPAN/Test/Dummy/Perl5/Make/ConfReq.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-ConfReq && \
		$(PERL) Makefile.PL open_the_backdoor && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-ConfReq-1.00.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features-1.06.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features/mymeta.yml \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features/lib/CPAN/Test/Dummy/Perl5/Make/Features.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Features && \
		$(PERL) Makefile.PL open_the_backdoor && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-Features-1.06.tar.gz ../ && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect-1.00.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect/lib/CPAN/Test/Dummy/Perl5/Make/Expect.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Expect && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-Expect-1.00.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Failearly-1.02.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Failearly/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Failearly/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Failearly/lib/CPAN/Test/Dummy/Perl5/Make/Failearly.pm
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Failearly && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-Failearly-1.02.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq-1.00.tar.gz: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/Changes \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/README \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/lib/CPAN/Test/Dummy/Perl5/Make/UnsatPrereq.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-UnsatPrereq/ && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-UnsatPrereq-1.00.tar.gz .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip-1.03.zip: \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip/MANIFEST \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip/Makefile.PL \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip/lib/CPAN/Test/Dummy/Perl5/Make/Zip.pm \
	t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip/t/00_load.t
	cd t/CPAN/authors/id/A/AN/ANDK/CPAN-Test-Dummy-Perl5-Make-Zip && \
		$(PERL) Makefile.PL && \
		$(MAKE) dist && \
		mv CPAN-Test-Dummy-Perl5-Make-Zip-1.03.zip .. && \
		$(MAKE) clean
	ls -l $@

t/CPAN/authors/id/A/AN/ANDK/NotInChecksums-0.000.tar.gz :
	echo " ----No content---- " > t/CPAN/authors/id/A/AN/ANDK/tempfile
	cd t/CPAN/authors/id/A/AN/ANDK && tar cvzf NotInChecksums-0.000.tar.gz tempfile
	$(RM) t/CPAN/authors/id/A/AN/ANDK/tempfile
	ls -l $@

#
#
#

clean ::
	$(RM) t/CPAN/authors/id/A/AN/ANDK/*/Build \
		t/CPAN/authors/id/A/AN/ANDK/*/Makefile.old
	$(RM_RF) t/CPAN/authors/id/A/AN/ANDK/*/_build

no_CR : META.yml
	$(PERL) bin/no_CR.pl MANIFEST

foreign-prefs : dd-prefs st-prefs

dd-prefs ::
	`echo $(PERL) | sed -e 's/perl$$/slaymake/'` dd-prefs

st-prefs ::

chlog ::

};

  for my $base (@main::ST_PREFS) {
    push @m, qq{
st-prefs :: $base.st

};
    if ($HAVE_YAML_SYCK) {
      push @m, qq{$base.st : Makefile
	\$(PERL) -MYAML::Syck=LoadFile -MStorable=nstore -e '\$\$x=shift; \@y=LoadFile("\$\$x.yml"); nstore(\\\@y, "\$\$x.st")' $base

};
    }
  }

  join "", @m;
}

sub dist_test {
  return q{
# if we depend on $(DISTVNAME).tar$(SUFFIX), then the rest of the
# Makefile breaks our intent to NOT remake dist
disttest :
	rm -rf $(DISTVNAME)
	tar xvzf $(DISTVNAME).tar$(SUFFIX)
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)

distdir ::
	touch $(DISTVNAME)/SIGNATURE && $(CP) $(DISTVNAME)/SIGNATURE ./SIGNATURE
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	$(CP) $(DISTVNAME)/MANIFEST  ./MANIFEST

}
}

sub distdir {
  my $self = shift;
  my $out = $self->SUPER::distdir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}

# dist_dir was the name in very old MakeMaker as of 5.005_04
sub dist_dir {
  my $self = shift;
  my $out = $self->SUPER::dist_dir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}
