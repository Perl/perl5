#!/usr/bin/perl -w

# Wherein we ensure the INST_* and INSTALL* variables are set correctly
# when various PREFIX variables are set.
#
# Essentially, this test is a Makefile.PL.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;
use Test::More tests => 38;
use MakeMaker::Test::Utils;
use ExtUtils::MakeMaker;
use File::Spec;
use TieOut;
use Config;

my $Is_VMS = $^O eq 'VMS';

chdir 't';

perl_lib;

$| = 1;

my $Makefile = makefile_name;
my $Curdir = File::Spec->curdir;
my $Updir  = File::Spec->updir;

ok( chdir 'Big-Dummy', "chdir'd to Big-Dummy" ) ||
  diag("chdir failed: $!");

my $stdout = tie *STDOUT, 'TieOut' or die;

my $mm = WriteMakefile(
    NAME          => 'Big::Dummy',
    VERSION_FROM  => 'lib/Big/Dummy.pm',
    PREREQ_PM     => {},
    PERL_CORE     => $ENV{PERL_CORE},
);

like( $stdout->read, qr{
                        Writing\ $Makefile\ for\ Big::Liar\n
                        Big::Liar's\ vars\n
                        INST_LIB\ =\ \S+\n
                        INST_ARCHLIB\ =\ \S+\n
                        Writing\ $Makefile\ for\ Big::Dummy\n
}x );

isa_ok( $mm, 'ExtUtils::MakeMaker' );

is( $mm->{NAME}, 'Big::Dummy',  'NAME' );
is( $mm->{VERSION}, 0.01,            'VERSION' );

foreach my $prefix (qw(PREFIX PERLPREFIX SITEPREFIX VENDORPREFIX)) {
    unlike( $mm->{$prefix}, qr/\$\(PREFIX\)/ );
    like( $mm->{$prefix}, qr/^\$\(DESTDIR\)/, 
                                   "\$(DESTDIR) prepended to $prefix" );
}


my $PREFIX = File::Spec->catdir('foo', 'bar');
$mm = WriteMakefile(
    NAME          => 'Big::Dummy',
    VERSION_FROM  => 'lib/Big/Dummy.pm',
    PREREQ_PM     => {},
    PERL_CORE     => $ENV{PERL_CORE},
    PREFIX        => $PREFIX,
);
like( $stdout->read, qr{
                        Writing\ $Makefile\ for\ Big::Liar\n
                        Big::Liar's\ vars\n
                        INST_LIB\ =\ \S+\n
                        INST_ARCHLIB\ =\ \S+\n
                        Writing\ $Makefile\ for\ Big::Dummy\n
}x );
undef $stdout;
untie *STDOUT;

is( $mm->{PREFIX}, '$(DESTDIR)'.$PREFIX,   'PREFIX' );

foreach my $prefix (qw(PERLPREFIX SITEPREFIX VENDORPREFIX)) {
    is( $mm->{$prefix}, '$(DESTDIR)$(PREFIX)', 
                                       "\$(PREFIX) overrides $prefix" );
}

is( !!$mm->{PERL_CORE}, !!$ENV{PERL_CORE}, 'PERL_CORE' );

my($perl_src, $mm_perl_src);
if( $ENV{PERL_CORE} ) {
    $perl_src = File::Spec->catdir($Updir, $Updir);
    $perl_src = File::Spec->canonpath($perl_src);
    $mm_perl_src = File::Spec->canonpath($mm->{PERL_SRC});
}
else {
    $mm_perl_src = $mm->{PERL_SRC};
}

is( $mm_perl_src, $perl_src,     'PERL_SRC' );


# Every INSTALL* variable must start with some PREFIX.
my %Install_Vars = (
 PERL   => [qw(archlib    privlib   bin       man1dir       man3dir   script)],
 SITE   => [qw(sitearch   sitelib   sitebin   siteman1dir   siteman3dir)],
 VENDOR => [qw(vendorarch vendorlib vendorbin vendorman1dir vendorman3dir)]
);

while( my($type, $vars) = each %Install_Vars) {

    SKIP: foreach my $var (@$vars) {
        skip "VMS must expand macros in INSTALL* vars", scalar @$vars 
          if $Is_VMS;

        my $prefix = '$('.$type.'PREFIX)';

        # support for man page skipping
        $prefix = 'none' if $type eq 'PERL' && 
                            $var =~ /man/ && 
                            !$Config{"install$var"};
        like( $mm->{uc "install$var"}, qr/^\Q$prefix\E/, "$prefix + $var" );
    }
}

# Check that when installman*dir isn't set in Config no man pages
# are generated.
{
    undef *ExtUtils::MM_Unix::Config;
    %ExtUtils::MM_Unix::Config = %Config;
    $ExtUtils::MM_Unix::Config{installman1dir} = '';
    $ExtUtils::MM_Unix::Config{installman3dir} = '';

    my $wibble = File::Spec->catdir(qw(wibble and such));
    my $stdout = tie *STDOUT, 'TieOut' or die;
    my $mm = WriteMakefile(
                           NAME          => 'Big::Dummy',
                           VERSION_FROM  => 'lib/Big/Dummy.pm',
                           PREREQ_PM     => {},
                           PERL_CORE     => $ENV{PERL_CORE},
                           PREFIX        => $PREFIX,
                           INSTALLMAN1DIR=> $wibble,
                          );

    is( $mm->{INSTALLMAN1DIR}, $wibble );
    is( $mm->{INSTALLMAN3DIR}, 'none'  );
}
