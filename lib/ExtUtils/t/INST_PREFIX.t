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
use Test::More tests => 24;
use MakeMaker::Test::Utils;
use ExtUtils::MakeMaker;
use File::Spec;
use TieOut;
use Config;

$ENV{PERL_CORE} ? chdir '../lib/ExtUtils/t' : chdir 't';

perl_lib;

$| = 1;

my $Makefile = makefile_name;
my $Curdir = File::Spec->curdir;
my $Updir  = File::Spec->updir;

ok( chdir 'Big-Fat-Dummy', "chdir'd to Big-Fat-Dummy" ) ||
  diag("chdir failed: $!");

my $stdout = tie *STDOUT, 'TieOut' or die;
my $mm = WriteMakefile(
    NAME          => 'Big::Fat::Dummy',
    VERSION_FROM  => 'lib/Big/Fat/Dummy.pm',
    PREREQ_PM     => {},
    PERL_CORE     => $ENV{PERL_CORE},
    PREFIX        => 'foo/bar',
);
like( $stdout->read, qr{
                        Writing\ $Makefile\ for\ Big::Fat::Liar\n
                        Big::Fat::Liar's\ vars\n
                        INST_LIB\ =\ \S+\n
                        INST_ARCHLIB\ =\ \S+\n
                        Writing\ $Makefile\ for\ Big::Fat::Dummy\n
}x );
undef $stdout;
untie *STDOUT;

isa_ok( $mm, 'ExtUtils::MakeMaker' );

is( $mm->{NAME}, 'Big::Fat::Dummy',  'NAME' );
is( $mm->{VERSION}, 0.01,            'VERSION' );

is( $mm->{PREFIX}, 'foo/bar',   'PREFIX' );

is( !!$mm->{PERL_CORE}, !!$ENV{PERL_CORE}, 'PERL_CORE' );

my($perl_src, $mm_perl_src);
if( $ENV{PERL_CORE} ) {
    $perl_src = File::Spec->catdir($Updir, $Updir, $Updir, $Updir);
    $perl_src = File::Spec->canonpath($perl_src);
    $mm_perl_src = File::Spec->canonpath($mm->{PERL_SRC});
}
else {
    $mm_perl_src = $mm->{PERL_SRC};
}

is( $mm_perl_src, $perl_src,     'PERL_SRC' );


# Every INSTALL* variable must start with some PREFIX.
my @Perl_Install = qw(archlib    privlib   bin     script 
                      man1dir       man3dir);
my @Site_Install = qw(sitearch   sitelib   sitebin        
                      siteman1dir siteman3dir);
my @Vend_Install = qw(vendorarch vendorlib vendorbin 
                      vendorman1dir vendorman3dir);

foreach my $var (@Perl_Install) {
    like( $mm->{uc "install$var"}, qr/^\$\(PREFIX\)/, "PREFIX + $var" );
}

foreach my $var (@Site_Install) {
    like( $mm->{uc "install$var"}, qr/^\$\(SITEPREFIX\)/, 
                                                    "SITEPREFIX + $var" );
}

foreach my $var (@Vend_Install) {
    like( $mm->{uc "install$var"}, qr/^\$\(VENDORPREFIX\)/,
                                                    "VENDORPREFIX + $var" );
}
