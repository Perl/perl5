#!/usr/bin/perl -w

# This test puts MakeMaker through the paces of a basic perl module
# build, test and installation of the Big::Fat::Dummy module.

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
use Config;

use Test::More tests => 52;
use MakeMaker::Test::Utils;
use File::Find;
use File::Spec;

# 'make disttest' sets a bunch of environment variables which interfere
# with our testing.
delete @ENV{qw(PREFIX LIB MAKEFLAGS)};

my $perl = which_perl();
my $Is_VMS = $^O eq 'VMS';

chdir($Is_VMS ? 'BFD_TEST_ROOT:[t]' : 't');


perl_lib;

my $Touch_Time = calibrate_mtime();

$| = 1;

ok( chdir 'Big-Dummy', "chdir'd to Big-Dummy" ) ||
  diag("chdir failed: $!");

my @mpl_out = run(qq{$perl Makefile.PL "PREFIX=dummy-install"});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

my $makefile = makefile_name();
ok( grep(/^Writing $makefile for Big::Dummy/, 
         @mpl_out) == 1,
                                           'Makefile.PL output looks right');

ok( grep(/^Current package is: main$/,
         @mpl_out) == 1,
                                           'Makefile.PL run in package main');

ok( -e $makefile,       'Makefile exists' );

# -M is flakey on VMS
my $mtime = (stat($makefile))[9];
cmp_ok( $Touch_Time, '<=', $mtime,  '  its been touched' );

END { unlink makefile_name(), makefile_backup() }

my $make = make_run();

{
    # Supress 'make manifest' noise
    local $ENV{PERL_MM_MANIFEST_VERBOSE} = 0;
    my $manifest_out = run("$make manifest");
    ok( -e 'MANIFEST',      'make manifest created a MANIFEST' );
    ok( -s 'MANIFEST',      '  its not empty' );
}

END { unlink 'MANIFEST'; }


my $ppd_out = run("$make ppd");
is( $?, 0,                      '  exited normally' ) || diag $ppd_out;
ok( open(PPD, 'Big-Dummy.ppd'), '  .ppd file generated' );
my $ppd_html;
{ local $/; $ppd_html = <PPD> }
close PPD;
like( $ppd_html, qr{^<SOFTPKG NAME="Big-Dummy" VERSION="0,01,0,0">}m, 
                                                           '  <SOFTPKG>' );
like( $ppd_html, qr{^\s*<TITLE>Big-Dummy</TITLE>}m,        '  <TITLE>'   );
like( $ppd_html, qr{^\s*<ABSTRACT>Try "our" hot dog's</ABSTRACT>}m,         
                                                           '  <ABSTRACT>');
like( $ppd_html, 
      qr{^\s*<AUTHOR>Michael G Schwern &lt;schwern\@pobox.com&gt;</AUTHOR>}m,
                                                           '  <AUTHOR>'  );
like( $ppd_html, qr{^\s*<IMPLEMENTATION>}m,          '  <IMPLEMENTATION>');
like( $ppd_html, qr{^\s*<DEPENDENCY NAME="strict" VERSION="0,0,0,0" />}m,
                                                           '  <DEPENDENCY>' );
like( $ppd_html, qr{^\s*<OS NAME="$Config{osname}" />}m,
                                                           '  <OS>'      );
like( $ppd_html, qr{^\s*<ARCHITECTURE NAME="$Config{archname}" />}m,  
                                                           '  <ARCHITECTURE>');
like( $ppd_html, qr{^\s*<CODEBASE HREF="" />}m,            '  <CODEBASE>');
like( $ppd_html, qr{^\s*</IMPLEMENTATION>}m,           '  </IMPLEMENTATION>');
like( $ppd_html, qr{^\s*</SOFTPKG>}m,                      '  </SOFTPKG>');
END { unlink 'Big-Dummy.ppd' }


my $test_out = run("$make test");
like( $test_out, qr/All tests successful/, 'make test' );
is( $?, 0,                                 '  exited normally' );

# Test 'make test TEST_VERBOSE=1'
my $make_test_verbose = make_macro($make, 'test', TEST_VERBOSE => 1);
$test_out = run("$make_test_verbose");
like( $test_out, qr/ok \d+ - TEST_VERBOSE/, 'TEST_VERBOSE' );
like( $test_out, qr/All tests successful/,  '  successful' );
is( $?, 0,                                  '  exited normally' );


my $install_out = run("$make install");
is( $?, 0, 'install' ) || diag $install_out;
like( $install_out, qr/^Installing /m );
like( $install_out, qr/^Writing /m );

ok( -r 'dummy-install',     '  install dir created' );
my %files = ();
find( sub { 
    # do it case-insensitive for non-case preserving OSs
    $files{lc $_} = $File::Find::name; 
}, 'dummy-install' );
ok( $files{'dummy.pm'},     '  Dummy.pm installed' );
ok( $files{'liar.pm'},      '  Liar.pm installed'  );
ok( $files{'.packlist'},    '  packlist created'   );
ok( $files{'perllocal.pod'},'  perllocal.pod created' );


SKIP: {
    skip "VMS install targets do not preserve PREFIX", 8 if $Is_VMS;

    $install_out = run("$make install PREFIX=elsewhere");
    is( $?, 0, 'install with PREFIX override' ) || diag $install_out;
    like( $install_out, qr/^Installing /m );
    like( $install_out, qr/^Writing /m );

    ok( -r 'elsewhere',     '  install dir created' );
    %files = ();
    find( sub { $files{$_} = $File::Find::name; }, 'elsewhere' );
    ok( $files{'Dummy.pm'},     '  Dummy.pm installed' );
    ok( $files{'Liar.pm'},      '  Liar.pm installed'  );
    ok( $files{'.packlist'},    '  packlist created'   );
    ok( $files{'perllocal.pod'},'  perllocal.pod created' );
}


my $dist_test_out = run("$make disttest");
is( $?, 0, 'disttest' ) || diag($dist_test_out);

# Test META.yml generation
use ExtUtils::Manifest qw(maniread);
ok( -f 'META.yml',    'META.yml written' );
my $manifest = maniread();
# VMS is non-case preserving, so we can't know what the MANIFEST will
# look like. :(
_normalize($manifest);
is( $manifest->{'meta.yml'}, 'Module meta-data in YAML' );

# Test NO_META META.yml suppression
unlink 'META.yml';
ok( !-f 'META.yml',   'META.yml deleted' );
@mpl_out = run(qq{$perl Makefile.PL "NO_META=1"});
cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) || diag(@mpl_out);
my $metafile_out = run("$make metafile");
is( $?, 0, 'metafile' ) || diag($metafile_out);
ok( !-f 'META.yml',   'META.yml generation suppressed by NO_META' );


# Make sure init_dirscan doesn't go into the distdir
@mpl_out = run(qq{$perl Makefile.PL "PREFIX=dummy-install"});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) || diag(@mpl_out);

ok( grep(/^Writing $makefile for Big::Dummy/, @mpl_out) == 1,
                                'init_dirscan skipped distdir') || 
  diag(@mpl_out);

# I know we'll get ignored errors from make here, that's ok.
# Send STDERR off to oblivion.
open(SAVERR, ">&STDERR") or die $!;
open(STDERR, ">".File::Spec->devnull) or die $!;

my $realclean_out = run("$make realclean");
is( $?, 0, 'realclean' ) || diag($realclean_out);

open(STDERR, ">&SAVERR") or die $!;
close SAVERR;


sub _normalize {
    my $hash = shift;

    while(my($k,$v) = each %$hash) {
        delete $hash->{$k};
        $hash->{lc $k} = $v;
    }
}
