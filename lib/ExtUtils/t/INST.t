#!/usr/bin/perl -w

# Wherein we ensure the INST_* and INSTALL* variables are set correctly
# according to the values of PREFIX, SITEPREFIX, INSTALLDIRS, etc...
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
use Test::More tests => 17;
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

my $config_prefix = $^O eq 'VMS' ? VMS::Filespec::unixify($Config{prefix})
                                 : $Config{prefix};
is( $mm->{PREFIX}, $config_prefix,   'PREFIX' );

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


# PERM_*
is( $mm->{PERM_RW},  644,    'PERM_RW' );
is( $mm->{PERM_RWX}, 755,    'PERM_RWX' );


# INST_*
is( $mm->{INST_ARCHLIB}, 
    $mm->{PERL_CORE} ? $mm->{PERL_ARCHLIB}
                     : File::Spec->catdir($Curdir, 'blib', 'arch'),
                                     'INST_ARCHLIB');
is( $mm->{INST_BIN},     File::Spec->catdir($Curdir, 'blib', 'bin'),
                                     'INST_BIN' );

is( keys %{$mm->{CHILDREN}}, 1 );
my($child_pack) = keys %{$mm->{CHILDREN}};
my $c_mm = $mm->{CHILDREN}{$child_pack};
is( $c_mm->{INST_ARCHLIB}, 
    $c_mm->{PERL_CORE} ? $c_mm->{PERL_ARCHLIB}
                       : File::Spec->catdir($Updir, 'blib', 'arch'),
                                     'CHILD INST_ARCHLIB');
is( $c_mm->{INST_BIN},     File::Spec->catdir($Updir, 'blib', 'bin'),
                                     'CHILD INST_BIN' );


my $inst_lib = File::Spec->catdir($Curdir, 'blib', 'lib');
is( $mm->{INST_LIB}, 
    $mm->{PERL_CORE} ? $mm->{PERL_LIB} : $inst_lib,     'INST_LIB' );


# INSTALL*
is( $mm->{INSTALLDIRS}, 'site',     'INSTALLDIRS' );
