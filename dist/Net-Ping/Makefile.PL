use strict;
use warnings;
use v5.002; # not using our in the CPAN release
use ExtUtils::MakeMaker;

my @extras = ();
my $EUMM_VER = $ExtUtils::MakeMaker::VERSION;
my @AUTHORS = (
      'Reini Urban <rurban@cpan.org>',
      'Steve Peters <steve@fisharerojo.org>',
      'Matthew Musgrove <mr.muskrat@gmail.com>',
      'Karl Williamson <khw@cpan.org>',
      'Brian Fraser <fraserbn@gmail.com>',
      'Mark Gardner <mjgardner@cpan.org>',
  );

push @extras,
  AUTHOR => join(", ", @AUTHORS)
  if $EUMM_VER gt '5.4301' and $EUMM_VER lt '6.57_02';
push @extras,
  AUTHOR => [ @AUTHORS ]
  if $EUMM_VER ge '6.57_02';
push @extras, SIGN => 1
  if $EUMM_VER ge '6.18';
push @extras, LICENSE => 'perl_5'
  if $EUMM_VER ge '6.31' and $EUMM_VER le '6.46';
push @extras,
  META_MERGE => {
      'meta-spec' => { version => 2 },
        resources   => {
            # TODO: 26 old issues still open at RT
            # https://rt.cpan.org/Public/Dist/Display.html?Name=Net-Ping
            bugtracker  => 'https://github.com/rurban/Net-Ping/issues',
            repository  => {
                type => 'git',
                url => 'https://github.com/rurban/Net-Ping.git',
                web => 'https://github.com/rurban/Net-Ping',
            },
            license     => [ 'http://dev.perl.org/licenses/' ],
        },
        release_status => 'stable',
  }
  if $EUMM_VER gt '6.46';

WriteMakefile(
  NAME   => 'Net::Ping',
  VERSION_FROM  => 'lib/Net/Ping.pm',
  ABSTRACT_FROM => 'lib/Net/Ping.pm',
  PREREQ_PM     => {
    'Socket'      => '2.007',
    'Test::More'  => 0,
    'Time::HiRes' => 0,
  },
  TEST_REQUIRES => {
    'Test::Pod'           => '1.22',
    'Test::More'          => 0,
  },
  INSTALLDIRS => ($ENV{PERL_CORE} ? 'perl' : 'site'),
  clean      => { FILES => 'Net-Ping-*' },
  @extras
);

package MY;

sub depend {
  "
README : lib/Net/Ping.pm
	pod2text lib/Net/Ping.pm > README
release : dist
	if test \"\$(shell git rev-parse --abbrev-ref HEAD)\" != \"master\" || \\
           test \"\$(shell git diff --raw)\" != \"\" || \\
           test \"\$(shell git diff --cached --raw)\" != \"\" ; then \\
          echo 'You are not on a clean master branch, aborting.'; \\
          exit 1; \\
	fi
	-git tag -f \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags
"
}
