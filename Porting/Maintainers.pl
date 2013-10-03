#!perl
# A simple listing of core files that have specific maintainers,
# or at least someone that can be called an "interested party".
# Also, a "module" does not necessarily mean a CPAN module, it
# might mean a file or files or a subdirectory.
# Most (but not all) of the modules have dual lives in the core
# and in CPAN.

package Maintainers;

use utf8;
use File::Glob qw(:case);

%Maintainers = (
    'ABIGAIL'   => 'Abigail <abigail@abigail.be>',
    'AVAR'      => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
    'CBERRY'    => 'Craig Berry <craigberry@mac.com>',
    'ELIZABETH' => 'Elizabeth Mattijsen <liz@dijkmat.nl>',
    'JDB'       => 'Jan Dubois <jand@activestate.com>',
    'laun'      => 'Wolfgang Laun <Wolfgang.Laun@alcatel.at>',
    'LWALL'     => 'Larry Wall <lwall@cpan.org>',
    'MJD'       => 'Mark-Jason Dominus <mjd@plover.com>',
    'PMQS'      => 'Paul Marquess <pmqs@cpan.org>',
    'PVHP'      => 'Peter Prymmer <pvhp@best.com>',
    'SARTAK'    => 'Shawn M Moore <sartak@gmail.com>',
    'SBURKE'    => 'Sean Burke <sburke@cpan.org>',
    'SMCCAM'    => 'Stephen McCamant <smccam@cpan.org>',
);

# IGNORABLE: files which, if they appear in the root of a CPAN
# distribution, need not appear in core (i.e. core-cpan-diff won't
# complain if it can't find them)

@IGNORABLE = qw(
    .cvsignore .dualLivedDiffConfig .gitignore
    ANNOUNCE Announce Artistic AUTHORS BENCHMARK BUGS Build.PL
    CHANGELOG ChangeLog Changelog CHANGES Changes CONTRIBUTING COPYING Copying
    cpanfile CREDITS dist.ini GOALS HISTORY INSTALL INSTALL.SKIP LICENSE
    Makefile.PL MANIFEST MANIFEST.SKIP META.json META.yml MYMETA.json
    MYMETA.yml NEW NOTES perlcritic.rc ppport.h README README.PATCHING
    SIGNATURE THANKS TODO Todo VERSION WHATSNEW
);

# Each entry in the  %Modules hash roughly represents a distribution,
# except when DISTRIBUTION is set, where it *exactly* represents a single
# CPAN distribution.

# The keys of %Modules are human descriptions of the distributions, and
# may not exactly match a module or distribution name. Distributions
# which have an obvious top-level module associated with them will usually
# have a key named for that module, e.g. 'Archive::Extract' for
# Archive-Extract-N.NN.tar.gz; the remaining keys are likely to be based
# on the name of the distribution, e.g. 'Locale-Codes' for
# Locale-Codes-N.NN.tar.gz'.

# MAINTAINER indicates who the current maintainer of the module is.  For
# modules with no MAINTAINER field given, this is understood to be either
# the Perl 5 Porters if there is no DISTRIBUTION field or the UPSTREAM
# field is set to 'blead', or else the CPAN author whose PAUSE user ID
# forms the first part of the DISTRIBUTION value, e.g. 'BINGOS' in the
# case of 'BINGOS/Archive-Tar-1.92.tar.gz'.  (PAUSE's View Permissions
# page may be consulted to find other authors who have owner or co-maint
# permissions for the module in question.)  The few explicitly listed
# MAINTAINERs refer to authors whose email address is listed in the
# %Maintainers hash above.

# FILES is a list of filenames, glob patterns, and directory
# names to be recursed down, which collectively generate a complete list
# of the files associated with the distribution.

# UPSTREAM indicates where patches should go. undef implies
# that this hasn't been discussed for the module at hand.
# "blead" indicates that the copy of the module in the blead
# sources is to be considered canonical, "cpan" means that the
# module on CPAN is to be patched first.

# BUGS is an email or url to post bug reports.  For modules with
# UPSTREAM => 'blead', use perl5-porters@perl.org.  rt.cpan.org
# appears to automatically provide a URL for CPAN modules; any value
# given here overrides the default:
# http://rt.cpan.org/Public/Dist/Display.html?Name=$ModuleName

# DISTRIBUTION names the tarball on CPAN which (allegedly) the files
# included in core are derived from. Note that the file's version may not
# necessarily match the newest version on CPAN.

# EXCLUDED is a list of files to be excluded from a CPAN tarball before
# comparing the remaining contents with core. Each item can either be a
# full pathname (eg 't/foo.t') or a pattern (e.g. qr{^t/}).
# It defaults to the empty list.

# CUSTOMIZED is a list of files that have been customized within the
# Perl core.  Use this whenever patching a cpan upstream distribution
# or whenever we expect to have a file that differs from the tarball.
# If the file in blead matches the file in the tarball from CPAN,
# Porting/core-cpan-diff will warn about it, as it indicates an expected
# customization might have been lost when updating from upstream.  The
# path should be relative to the distribution directory.  If the upstream
# distribution should be modified to incorporate the change then be sure
# to raise a ticket for it on rt.cpan.org and add a comment alongside the
# list of CUSTOMIZED files noting the ticket number.

# DEPRECATED contains the *first* version of Perl in which the module
# was considered deprecated.  It should only be present if the module is
# actually deprecated.  Such modules should use deprecated.pm to
# issue a warning if used.  E.g.:
#
#     use if $] >= 5.011, 'deprecate';
#

# MAP is a hash that maps CPAN paths to their core equivalents.
# Each key represents a string prefix, with longest prefixes checked
# first. The first match causes that prefix to be replaced with the
# corresponding key. For example, with the following MAP:
#   {
#     'lib/'     => 'lib/',
#     ''     => 'lib/Foo/',
#   },
#
# these files are mapped as shown:
#
#    README     becomes lib/Foo/README
#    lib/Foo.pm becomes lib/Foo.pm
#
# The default is dependent on the type of module.
# For distributions which appear to be stored under ext/, it defaults to:
#
#   { '' => 'ext/Foo-Bar/' }
#
# otherwise, it's
#
#   {
#     'lib/'     => 'lib/',
#     ''     => 'lib/Foo/Bar/',
#   }

%Modules = (

    'AnyDBM_File' => {
        'FILES'       => q[lib/AnyDBM_File.{pm,t}],
        'UPSTREAM'    => 'blead',
    },

    'Archive::Tar' => {
        'DISTRIBUTION' => 'BINGOS/Archive-Tar-1.92.tar.gz',
        'FILES'        => q[cpan/Archive-Tar],
        'UPSTREAM'     => 'cpan',
        'BUGS'         => 'bug-archive-tar@rt.cpan.org',
    },

    'Attribute::Handlers' => {
        'DISTRIBUTION' => 'SMUELLER/Attribute-Handlers-0.93.tar.gz',
        'FILES'        => q[dist/Attribute-Handlers],
        'UPSTREAM'     => 'blead',
    },

    'attributes' => {
        'FILES'      => q[ext/attributes],
        'UPSTREAM'   => 'blead',
    },

    'autodie' => {
        'DISTRIBUTION' => 'PJF/autodie-2.22.tar.gz',
        'FILES'        => q[cpan/autodie],
        'EXCLUDED'     => [
            qr{benchmarks},
            # All these tests depend upon external
            # modules that don't exist when we're
            # building the core.  Hence, they can
            # never run, and should not be merged.
            qw( t/author-critic.t
                t/boilerplate.t
                t/critic.t
                t/fork.t
                t/kwalitee.t
                t/lex58.t
                t/pod-coverage.t
                t/pod.t
                t/release-pod-coverage.t
                t/release-pod-syntax.t
                t/socket.t
                t/system.t
                )
        ],
        'CUSTOMIZED'   => [
            # Waiting to be merged upstream: see CPAN RT#87237
            qw(	t/utf8_open.t ),
        ],
        'UPSTREAM'   => 'cpan',
    },

    'AutoLoader' => {
        'DISTRIBUTION' => 'SMUELLER/AutoLoader-5.73.tar.gz',
        'FILES'        => q[cpan/AutoLoader],
        'EXCLUDED'     => ['t/00pod.t'],
        'UPSTREAM'     => 'cpan',
    },

    'autouse' => {
        'DISTRIBUTION' => 'FLORA/autouse-1.07.tar.gz',
        'FILES'        => q[dist/autouse],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'B' => {
        'FILES'      => q[ext/B],
        'EXCLUDED'   => [
            qw( B/Concise.pm
                t/concise.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'B::Concise' => {
        'MAINTAINER' => 'SMCCAM',
        'FILES'      => q[ext/B/B/Concise.pm ext/B/t/concise.t],
        'UPSTREAM'   => 'blead',
    },

    'B::Debug' => {
        'DISTRIBUTION' => 'RURBAN/B-Debug-1.18.tar.gz',
        'FILES'        => q[cpan/B-Debug],
        'EXCLUDED'     => ['t/pod.t'],
        'UPSTREAM'     => 'cpan',
    },

    'B::Deparse' => {
        'MAINTAINER' => 'SMCCAM',
        'FILES'      => q[dist/B-Deparse],
        'UPSTREAM'   => 'blead',
    },

    'base' => {
        'DISTRIBUTION' => 'RGARCIA/base-2.18.tar.gz',
        'FILES'        => q[dist/base],
        'UPSTREAM'     => 'blead',
    },

    'Benchmark' => {
        'FILES'      => q[lib/Benchmark.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'bignum' => {
        'DISTRIBUTION' => 'FLORA/bignum-0.32.tar.gz',
        'FILES'        => q[dist/bignum],
        'EXCLUDED'     => [
            qr{^inc/Module/},
            qw( t/pod.t
                t/pod_cov.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Carp' => {
        'DISTRIBUTION' => 'ZEFRAM/Carp-1.32.tar.gz',
        'FILES'        => q[dist/Carp],
        'UPSTREAM'     => 'blead',
    },

    'CGI' => {
        'DISTRIBUTION' => 'MARKSTOS/CGI.pm-3.63.tar.gz',
        'FILES'        => q[cpan/CGI],
        'EXCLUDED'     => [
            qw( cgi_docs.html
                examples/WORLD_WRITABLE/18.157.1.253.sav
                t/gen-tests/gen-start-end-tags.pl
                t/fast.t
                ),
        ],
        'UPSTREAM'   => 'cpan',
    },

    'Class::Struct' => {
        'FILES'      => q[lib/Class/Struct.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Compress::Raw::Bzip2' => {
        'DISTRIBUTION' => 'PMQS/Compress-Raw-Bzip2-2.062.tar.gz',
        'FILES'        => q[cpan/Compress-Raw-Bzip2],
        'EXCLUDED'     => [
            qr{^t/Test/},
            'bzip2-src/bzip2-cpp.patch',
        ],
        'UPSTREAM' => 'cpan',
    },

    'Compress::Raw::Zlib' => {
        'DISTRIBUTION' => 'PMQS/Compress-Raw-Zlib-2.062.tar.gz',

        'FILES'    => q[cpan/Compress-Raw-Zlib],
        'EXCLUDED' => [
            qr{^t/Test/},
            qw( t/000prereq.t
                t/99pod.t
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'Config::Perl::V' => {
        'DISTRIBUTION' => 'HMBRAND/Config-Perl-V-0.19.tgz',
        'FILES'        => q[cpan/Config-Perl-V],
        'EXCLUDED'     => ['examples/show-v.pl'],
        'UPSTREAM'     => 'cpan',
    },

    'constant' => {
        'DISTRIBUTION' => 'SAPER/constant-1.27.tar.gz',
        'FILES'        => q[dist/constant],
        'EXCLUDED'     => [
            qw( t/00-load.t
                t/more-tests.t
                t/pod-coverage.t
                t/pod.t
                eg/synopsis.pl
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'CPAN' => {
        'DISTRIBUTION' => 'ANDK/CPAN-2.03-TRIAL.tar.gz',
        'FILES'        => q[cpan/CPAN],
        'EXCLUDED'     => [
            qr{^distroprefs/},
            qr{^inc/Test/},
            qr{^t/CPAN/authors/},
            qw( lib/CPAN/Admin.pm
                scripts/cpan-mirrors
                PAUSE2015.pub
                SlayMakefile
                t/00signature.t
                t/04clean_load.t
                t/12cpan.t
                t/13tarzip.t
                t/14forkbomb.t
                t/30shell.coverage
                t/30shell.t
                t/31sessions.t
                t/41distribution.t
                t/42distroprefs.t
                t/44cpanmeta.t
                t/43distroprefspref.t
                t/50pod.t
                t/51pod.t
                t/52podcover.t
                t/60credentials.t
                t/70_critic.t
                t/71_minimumversion.t
                t/CPAN/CpanTestDummies-1.55.pm
                t/CPAN/TestConfig.pm
                t/CPAN/TestMirroredBy
                t/CPAN/TestPatch.txt
                t/CPAN/modules/02packages.details.txt
                t/CPAN/modules/03modlist.data
                t/data/META-dynamic.json
                t/data/META-dynamic.yml
                t/data/META-static.json
                t/data/META-static.yml
                t/data/MYMETA.json
                t/data/MYMETA.yml
                t/local_utils.pm
                t/perlcriticrc
                t/yaml_code.yml
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    # Note: When updating CPAN-Meta the META.* files will need to be regenerated
    # perl -Icpan/CPAN-Meta/lib Porting/makemeta
    'CPAN::Meta' => {
        'DISTRIBUTION' => 'DAGOLDEN/CPAN-Meta-2.132661.tar.gz',
        'FILES'        => q[cpan/CPAN-Meta],
        'EXCLUDED'     => [
            qw(t/00-compile.t),
            qw[t/00-report-prereqs.t],
            qw(cpanfile),
            qr{^xt},
            qr{^history},
        ],
        'UPSTREAM' => 'cpan',
    },

    'CPAN::Meta::Requirements' => {
        'DISTRIBUTION' => 'DAGOLDEN/CPAN-Meta-Requirements-2.125.tar.gz',
        'FILES'        => q[cpan/CPAN-Meta-Requirements],
        'EXCLUDED'     => [
            qw(t/00-compile.t),
            qw(t/00-report-prereqs.t),
            qr{^xt},
            qr{^history},
        ],
        'UPSTREAM' => 'cpan',
    },

    'CPAN::Meta::YAML' => {
        'DISTRIBUTION' => 'DAGOLDEN/CPAN-Meta-YAML-0.010.tar.gz',
        'FILES'        => q[cpan/CPAN-Meta-YAML],
        'EXCLUDED'     => [
            't/00-compile.t',
            't/04_scalar.t',    # requires YAML.pm
            qr{^xt},
        ],
        'UPSTREAM' => 'cpan',
    },

    'Data::Dumper' => {
        'DISTRIBUTION' => 'SMUELLER/Data-Dumper-2.145.tar.gz',
        'FILES'        => q[dist/Data-Dumper],
        'UPSTREAM'     => 'blead',
    },

    'DB_File' => {
        'DISTRIBUTION' => 'PMQS/DB_File-1.829.tar.gz',
        'FILES'        => q[cpan/DB_File],
        'EXCLUDED'     => [
            qr{^patches/},
            qw( t/pod.t
                fallback.h
                fallback.xs
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'DBM_Filter' => {
        'FILES'      => q[lib/DBM_Filter.pm lib/DBM_Filter],
        'UPSTREAM'   => 'blead',
    },

    'Devel::Peek' => {
        'FILES'      => q[ext/Devel-Peek],
        'UPSTREAM'   => 'blead',
    },

    'Devel::PPPort' => {
        'DISTRIBUTION' => 'MHX/Devel-PPPort-3.21.tar.gz',
        'FILES'        => q[cpan/Devel-PPPort],
        'EXCLUDED'     => ['PPPort.pm'],    # we use PPPort_pm.PL instead
        'UPSTREAM'     => undef, # rjbs has asked mhx to have blead be upstream
    },

    'Devel::SelfStubber' => {
        'DISTRIBUTION' => 'FLORA/Devel-SelfStubber-1.05.tar.gz',
        'FILES'        => q[dist/Devel-SelfStubber],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'diagnostics' => {
        'FILES'      => q[lib/diagnostics.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Digest' => {
        'DISTRIBUTION' => 'GAAS/Digest-1.17.tar.gz',
        'FILES'        => q[cpan/Digest],
        'EXCLUDED'     => ['digest-bench'],
        'UPSTREAM'     => "cpan",
    },

    'Digest::MD5' => {
        'DISTRIBUTION' => 'GAAS/Digest-MD5-2.53.tar.gz',
        'FILES'        => q[cpan/Digest-MD5],
        'EXCLUDED'     => ['rfc1321.txt'],
        'UPSTREAM'     => "cpan",
    },

    'Digest::SHA' => {
        'DISTRIBUTION' => 'MSHELOR/Digest-SHA-5.85.tar.gz',
        'FILES'        => q[cpan/Digest-SHA],
        'EXCLUDED'     => [
            qw( t/pod.t
                t/podcover.t
                examples/dups
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'DirHandle' => {
        'FILES'      => q[lib/DirHandle.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Dumpvalue' => {
        'DISTRIBUTION' => 'FLORA/Dumpvalue-1.17.tar.gz',
        'FILES'        => q[dist/Dumpvalue],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'DynaLoader' => {
        'FILES'      => q[ext/DynaLoader],
        'UPSTREAM'   => 'blead',
    },

    'Encode' => {
        'DISTRIBUTION' => 'DANKOGAI/Encode-2.55.tar.gz',
        'FILES'        => q[cpan/Encode],
        'UPSTREAM'     => 'cpan',
    },

    'encoding::warnings' => {
        'DISTRIBUTION' => 'AUDREYT/encoding-warnings-0.11.tar.gz',
        'FILES'        => q[cpan/encoding-warnings],
        'EXCLUDED'     => [
            qr{^inc/Module/},
            qw(t/0-signature.t),
        ],
        'UPSTREAM' => undef,
    },

    'English' => {
        'FILES'      => q[lib/English.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Env' => {
        'DISTRIBUTION' => 'FLORA/Env-1.04.tar.gz',
        'FILES'        => q[dist/Env],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'Errno' => {
        'FILES'      => q[ext/Errno],
        'UPSTREAM'   => 'blead',
    },

    'Exporter' => {
        'DISTRIBUTION' => 'TODDR/Exporter-5.68.tar.gz',
        'FILES'        => q[dist/Exporter],
        'EXCLUDED' => [
            qw( t/pod.t
                t/use.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'ExtUtils::CBuilder' => {
        'DISTRIBUTION' => 'AMBS/ExtUtils/ExtUtils-CBuilder-0.280212.tar.gz',
        'FILES'        => q[dist/ExtUtils-CBuilder],
        'EXCLUDED'     => [
            qw(README.mkdn),
            qr{^xt},
        ],
        'UPSTREAM'     => 'blead',
    },

    'ExtUtils::Command' => {
        'DISTRIBUTION' => 'FLORA/ExtUtils-Command-1.18.tar.gz',
        'FILES'        => q[dist/ExtUtils-Command],
        'EXCLUDED'     => [qr{^t/release-}],
        'UPSTREAM'     => 'blead',
    },

    'ExtUtils::Constant' => {

        # Nick has confirmed that while we have diverged from CPAN,
        # this package isn't primarily maintained in core
        # Another release will happen "Sometime"
        'DISTRIBUTION' => '',    #'NWCLARK/ExtUtils-Constant-0.16.tar.gz',
        'FILES'    => q[cpan/ExtUtils-Constant],
        'EXCLUDED' => [
            qw( lib/ExtUtils/Constant/Aaargh56Hash.pm
                examples/perl_keyword.pl
                examples/perl_regcomp_posix_keyword.pl
                ),
        ],
        'UPSTREAM' => undef,
    },

    'ExtUtils::Install' => {
        'DISTRIBUTION' => 'YVES/ExtUtils-Install-1.54.tar.gz',
        'FILES'        => q[dist/ExtUtils-Install],
        'EXCLUDED'     => [
            qw( t/lib/Test/Builder.pm
                t/lib/Test/Builder/Module.pm
                t/lib/Test/More.pm
                t/lib/Test/Simple.pm
                t/pod-coverage.t
                t/pod.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'ExtUtils::MakeMaker' => {
        'DISTRIBUTION' => 'BINGOS/ExtUtils-MakeMaker-6.78.tar.gz',
        'FILES'        => q[cpan/ExtUtils-MakeMaker],
        'EXCLUDED'     => [
            qr{^t/lib/Test/},
            qr{^(bundled|my)/},
            qr{^t/Liblist_Kid.t},
            qr{^t/liblist/},
            qr{^\.perlcriticrc},
        ],
        'UPSTREAM' => 'cpan',
    },

    'ExtUtils::Manifest' => {
        'DISTRIBUTION' => 'FLORA/ExtUtils-Manifest-1.63.tar.gz',
        'FILES'        => q[dist/ExtUtils-Manifest],
        'EXCLUDED'     => [qr(t/release-.*\.t)],
        'UPSTREAM'     => 'blead',
    },

    'ExtUtils::ParseXS' => {
        'DISTRIBUTION' => 'SMUELLER/ExtUtils-ParseXS-3.22.tar.gz',
        'FILES'        => q[dist/ExtUtils-ParseXS],
        'UPSTREAM'     => 'blead',
    },

    'Fcntl' => {
        'FILES'      => q[ext/Fcntl],
        'UPSTREAM'   => 'blead',
    },

    'File::Basename' => {
        'FILES'      => q[lib/File/Basename.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'File::Compare' => {
        'FILES'      => q[lib/File/Compare.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'File::Copy' => {
        'FILES'      => q[lib/File/Copy.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'File::DosGlob' => {
        'FILES'      => q[ext/File-DosGlob],
        'UPSTREAM'   => 'blead',
    },

    'File::Fetch' => {
        'DISTRIBUTION' => 'BINGOS/File-Fetch-0.44.tar.gz',
        'FILES'        => q[cpan/File-Fetch],
        'UPSTREAM'     => 'cpan',
    },

    'File::Find' => {
        'FILES'      => q[ext/File-Find],
        'UPSTREAM'   => 'blead',
    },

    'File::Glob' => {
        'FILES'      => q[ext/File-Glob],
        'UPSTREAM'   => 'blead',
    },

    'File::Path' => {
        'DISTRIBUTION' => 'DLAND/File-Path-2.09.tar.gz',
        'FILES'        => q[cpan/File-Path],
        'EXCLUDED'     => [
            qw( eg/setup-extra-tests
                t/pod.t
                )
        ],
        'MAP' => {
            ''   => 'cpan/File-Path/lib/File/',
            't/' => 'cpan/File-Path/t/',
        },
        'UPSTREAM' => undef,
    },

    'File::stat' => {
        'FILES'      => q[lib/File/stat{.pm,*.t}],
        'UPSTREAM'   => 'blead',
    },

    'File::Temp' => {
        'DISTRIBUTION' => 'DAGOLDEN/File-Temp-0.2302.tar.gz',
        'FILES'        => q[cpan/File-Temp],
        'EXCLUDED'     => [
            qw( misc/benchmark.pl
                misc/results.txt
                ),
            qw(t/00-compile.t),
            qw[t/00-report-prereqs.t],
            qr{^xt},
        ],
        'UPSTREAM' => 'cpan',
    },

    'FileCache' => {
        'FILES'      => q[ext/FileCache],
        'UPSTREAM'   => 'blead',
    },

    'FileHandle' => {
        'FILES'      => q[lib/FileHandle.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Filter::Simple' => {
        'DISTRIBUTION' => 'SMUELLER/Filter-Simple-0.88.tar.gz',
        'FILES'        => q[dist/Filter-Simple],
        'EXCLUDED'     => [
            qr{^demo/}
        ],
        'UPSTREAM' => 'blead',
    },

    'Filter::Util::Call' => {
        'DISTRIBUTION' => 'RURBAN/Filter-1.49.tar.gz',
        'FILES'        => q[cpan/Filter-Util-Call
                 pod/perlfilter.pod
                ],
        'EXCLUDED' => [
            qr{^decrypt/},
            qr{^examples/},
            qr{^Exec/},
            qr{^lib/Filter/},
            qr{^tee/},
            qw( Call/Makefile.PL
                Call/ppport.h
                Call/typemap
                mytest
                t/cpp.t
                t/decrypt.t
                t/exec.t
                t/order.t
                t/pod.t
                t/sh.t
                t/tee.t
                t/z_kwalitee.t
                t/z_meta.t
                t/z_perl_minimum_version.t
                t/z_pod-coverage.t
                t/z_pod.t
                ),
        ],
        'MAP' => {
            'Call/'          => 'cpan/Filter-Util-Call/',
            'filter-util.pl' => 'cpan/Filter-Util-Call/filter-util.pl',
            'perlfilter.pod' => 'pod/perlfilter.pod',
            ''               => 'cpan/Filter-Util-Call/',
        },
        'UPSTREAM' => 'cpan',
    },

    'FindBin' => {
        'FILES'      => q[lib/FindBin.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'GDBM_File' => {
        'FILES'      => q[ext/GDBM_File],
        'UPSTREAM'   => 'blead',
    },

    'Getopt::Long' => {
        'DISTRIBUTION' => 'JV/Getopt-Long-2.42.tar.gz',
        'FILES'        => q[cpan/Getopt-Long],
        'EXCLUDED'     => [
            qr{^examples/},
            qw( perl-Getopt-Long.spec
                lib/newgetopt.pl
                t/gol-compat.t
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'Getopt::Std' => {
        'FILES'      => q[lib/Getopt/Std.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Hash::Util' => {
        'FILES'      => q[ext/Hash-Util],
        'UPSTREAM'   => 'blead',
    },

    'Hash::Util::FieldHash' => {
        'FILES'      => q[ext/Hash-Util-FieldHash],
        'UPSTREAM'   => 'blead',
    },

    'HTTP::Tiny' => {
        'DISTRIBUTION' => 'DAGOLDEN/HTTP-Tiny-0.036.tar.gz',
        'FILES'        => q[cpan/HTTP-Tiny],
        'EXCLUDED'     => [
            'cpanfile',
            't/00-compile.t',
            't/00-report-prereqs.t',
            't/200_live.t',
            't/200_live_local_ip.t',
            't/210_live_ssl.t',
            qr/^eg/,
            qr/^xt/
        ],
        'UPSTREAM' => 'cpan',
    },

    'I18N::Collate' => {
        'DISTRIBUTION' => 'FLORA/I18N-Collate-1.02.tar.gz',
        'FILES'        => q[dist/I18N-Collate],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'I18N::Langinfo' => {
        'FILES'      => q[ext/I18N-Langinfo],
        'UPSTREAM'   => 'blead',
    },

    'I18N::LangTags' => {
        'FILES'        => q[dist/I18N-LangTags],
        'UPSTREAM'     => 'blead',
    },

    'if' => {
        'DISTRIBUTION' => 'ILYAZ/modules/if-0.0601.tar.gz',
        'FILES'        => q[dist/if],
        'UPSTREAM'     => 'blead',
    },

    'IO' => {
        'DISTRIBUTION' => 'GBARR/IO-1.25.tar.gz',
        'FILES'        => q[dist/IO/],
        'EXCLUDED'     => ['t/test.pl'],
        'UPSTREAM'     => 'blead',
    },

    'IO-Compress' => {
        'DISTRIBUTION' => 'PMQS/IO-Compress-2.062.tar.gz',
        'FILES'        => q[cpan/IO-Compress],
        'EXCLUDED'     => [qr{t/Test/}],
        'UPSTREAM'     => 'cpan',
    },

    'IO::Zlib' => {
        'DISTRIBUTION' => 'TOMHUGHES/IO-Zlib-1.10.tar.gz',
        'FILES'        => q[cpan/IO-Zlib],
        'UPSTREAM'     => undef,
    },

    'IPC::Cmd' => {
        'DISTRIBUTION' => 'BINGOS/IPC-Cmd-0.84.tar.gz',
        'FILES'        => q[cpan/IPC-Cmd],
        'UPSTREAM'     => 'cpan',
    },

    'IPC::Open3' => {
        'FILES'      => q[ext/IPC-Open3],
        'UPSTREAM'   => 'blead',
    },

    'IPC::SysV' => {
        'DISTRIBUTION' => 'MHX/IPC-SysV-2.04.tar.gz',
        'FILES'        => q[cpan/IPC-SysV],
        'EXCLUDED'     => [
            qw( const-c.inc
                const-xs.inc
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'JSON::PP' => {
        'DISTRIBUTION' => 'MAKAMAKA/JSON-PP-2.27202.tar.gz',
        'FILES'        => q[cpan/JSON-PP],
        'EXCLUDED'     => [
            't/900_pod.t',    # Pod testing
        ],

        # Waiting to be merged upstream: see PERL RT#119825
        'CUSTOMIZED'   => [
            'lib/JSON/PP.pm',
        ],

        'UPSTREAM' => 'cpan',
    },

    'lib' => {
        'DISTRIBUTION' => 'SMUELLER/lib-0.63.tar.gz',
        'FILES'        => q[dist/lib/],
        'EXCLUDED'     => [
            qw( forPAUSE/lib.pm
                t/00pod.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'libnet' => {
        'DISTRIBUTION' => 'SHAY/libnet-1.23.tar.gz',
        'FILES'        => q[cpan/libnet],
        'EXCLUDED'     => [
            qw( Configure
                install-nomake
                ),
        ],
        # Customized for perl since we cannot use either an auto-generated
        # script or the version in the CPAN distro.
        'CUSTOMIZED' => ['Makefile.PL'],
        'UPSTREAM'   => 'cpan',
    },

    'Locale-Codes' => {
        'DISTRIBUTION' => 'SBECK/Locale-Codes-3.27.tar.gz',
        'FILES'        => q[cpan/Locale-Codes],
        'EXCLUDED'     => [
            qw( t/pod_coverage.t
                t/pod.t),
            qr{^t/runtests},
            qr{^t/runtests\.bat},
            qr{^internal/},
            qr{^examples/},
        ],
        'UPSTREAM' => 'cpan',
    },

    'Locale::Maketext' => {
        'DISTRIBUTION' => 'TODDR/Locale-Maketext-1.23.tar.gz',
        'FILES'        => q[dist/Locale-Maketext],
        'EXCLUDED'     => [
            qw(
                perlcriticrc
                t/00_load.t
                t/pod.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Locale::Maketext::Simple' => {
        'DISTRIBUTION' => 'JESSE/Locale-Maketext-Simple-0.21.tar.gz',
        'FILES'        => q[cpan/Locale-Maketext-Simple],
        'EXCLUDED'     => [qr{^inc/}],
        'UPSTREAM'     => 'cpan',
    },

    'mad' => {
        'MAINTAINER' => 'LWALL',
        'FILES'      => q[mad],
        'UPSTREAM'   => undef,
    },

    'Math::BigInt' => {
        'DISTRIBUTION' => 'PJACKLAM/Math-BigInt-1.997.tar.gz',
        'FILES'        => q[dist/Math-BigInt],
        'EXCLUDED'     => [
            qr{^inc/},
            qr{^examples/},
            qw( t/00sig.t
                t/01load.t
                t/02pod.t
                t/03podcov.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Math::BigInt::FastCalc' => {
        'DISTRIBUTION' => 'PJACKLAM/Math-BigInt-FastCalc-0.30.tar.gz',
        'FILES'        => q[dist/Math-BigInt-FastCalc],
        'EXCLUDED'     => [
            qr{^inc/},
            qw( t/00sig.t
                t/01load.t
                t/02pod.t
                t/03podcov.t
                ),

            # instead we use the versions of these test
            # files that come with Math::BigInt:
            qw( t/bigfltpm.inc
                t/bigfltpm.t
                t/bigintpm.inc
                t/bigintpm.t
                t/mbimbf.inc
                t/mbimbf.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Math::BigRat' => {
        'DISTRIBUTION' => 'PJACKLAM/Math-BigRat-0.2602.tar.gz',
        'FILES'        => q[dist/Math-BigRat],
        'EXCLUDED'     => [
            qr{^inc/},
            qw( t/00sig.t
                t/01load.t
                t/02pod.t
                t/03podcov.t
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Math::Complex' => {
        'DISTRIBUTION' => 'ZEFRAM/Math-Complex-1.59.tar.gz',
        'FILES'        => q[cpan/Math-Complex],
        'EXCLUDED'     => [
            qw( t/pod.t
                t/pod-coverage.t
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'Memoize' => {
        'DISTRIBUTION' => 'MJD/Memoize-1.03.tgz',
        'FILES'        => q[cpan/Memoize],
        'EXCLUDED'     => ['article.html'],
        'UPSTREAM'     => 'cpan',
    },

    'MIME::Base64' => {
        'DISTRIBUTION' => 'GAAS/MIME-Base64-3.14.tar.gz',
        'FILES'        => q[cpan/MIME-Base64],
        'EXCLUDED'     => ['t/bad-sv.t'],
        'UPSTREAM'     => 'cpan',
    },

    #
    # To update Module-Build in blead see
    # https://github.com/Perl-Toolchain-Gang/Module-Build/blob/master/devtools/patching_blead.pod
    #

    'Module::Build' => {
        'DISTRIBUTION' => 'LEONT/Module-Build-0.4007.tar.gz',
        'FILES'        => q[cpan/Module-Build],
        'EXCLUDED'     => [
            qw( t/par.t
                t/signature.t
                ),
            qr{^contrib/},
            qr{^inc},
        ],
        # Generated file, not part of the CPAN distro:
        'CUSTOMIZED' => ['lib/Module/Build/ConfigData.pm'],
        'DEPRECATED' => '5.019000',
        'UPSTREAM'   => 'cpan',
    },

    'Module::CoreList' => {
        'DISTRIBUTION' => 'BINGOS/Module-CoreList-2.99.tar.gz',
        'FILES'        => q[dist/Module-CoreList],
        'UPSTREAM'     => 'blead',
    },

    'Module::Load' => {
        'DISTRIBUTION' => 'BINGOS/Module-Load-0.24.tar.gz',
        'FILES'        => q[cpan/Module-Load],
        'UPSTREAM'     => 'cpan',
    },

    'Module::Load::Conditional' => {
        'DISTRIBUTION' => 'BINGOS/Module-Load-Conditional-0.58.tar.gz',
        'FILES'        => q[cpan/Module-Load-Conditional],
        'UPSTREAM'     => 'cpan',
    },

    'Module::Loaded' => {
        'DISTRIBUTION' => 'BINGOS/Module-Loaded-0.08.tar.gz',
        'FILES'        => q[cpan/Module-Loaded],
        'UPSTREAM'     => 'cpan',
    },

    'Module::Metadata' => {
        'DISTRIBUTION' => 'ETHER/Module-Metadata-1.000018.tar.gz',
        'FILES'        => q[cpan/Module-Metadata],
        'EXCLUDED'     => [
            qr{^maint},
            qr{^xt},
        ],
        'UPSTREAM' => 'cpan',
    },

    'mro' => {
        'FILES'      => q[ext/mro],
        'UPSTREAM'   => 'blead',
    },

    'NDBM_File' => {
        'FILES'      => q[ext/NDBM_File],
        'UPSTREAM'   => 'blead',
    },

    'Net::Ping' => {
        'DISTRIBUTION' => 'SMPETERS/Net-Ping-2.41.tar.gz',
        'FILES'        => q[dist/Net-Ping],
        'EXCLUDED'     => [
            qr{^.travis.yml},
            qr{^README.md},
        ],
        'UPSTREAM'     => 'blead',
    },

    'NEXT' => {
        'DISTRIBUTION' => 'FLORA/NEXT-0.65.tar.gz',
        'FILES'        => q[cpan/NEXT],
        'EXCLUDED'     => [qr{^demo/}],
        'UPSTREAM'     => 'cpan',
    },

    'ODBM_File' => {
        'FILES'      => q[ext/ODBM_File],
        'UPSTREAM'   => 'blead',
    },

    'Opcode' => {
        'FILES'      => q[ext/Opcode],
        'UPSTREAM'   => 'blead',
    },

    'overload' => {
        'FILES'      => q[lib/overload{.pm,.t,64.t}],
        'UPSTREAM'   => 'blead',
    },

    'Package::Constants' => {
        'DISTRIBUTION' => 'KANE/Package-Constants-0.02.tar.gz',
        'FILES'        => q[cpan/Package-Constants],
        'UPSTREAM'     => 'cpan',
    },

    'Params::Check' => {
        'DISTRIBUTION' => 'BINGOS/Params-Check-0.38.tar.gz',
        'EXCLUDED'     => ['Params-Check-0.26.tar.gz'],
        'FILES'        => q[cpan/Params-Check],
        'UPSTREAM'     => 'cpan',
    },

    'parent' => {
        'DISTRIBUTION' => 'CORION/parent-0.228.tar.gz',
        'FILES'        => q[cpan/parent],
        'UPSTREAM'     => undef,
    },

    'Parse::CPAN::Meta' => {
        'DISTRIBUTION' => 'DAGOLDEN/Parse-CPAN-Meta-1.4409.tar.gz',
        'FILES'        => q[cpan/Parse-CPAN-Meta],
        'EXCLUDED'     => [
            qw(t/00-compile.t),
            qw[t/00-report-prereqs.t],
            qw(cpanfile),
            qr{^xt},
        ],
        'UPSTREAM'     => 'cpan',
    },

    'PathTools' => {
        'DISTRIBUTION' => 'SMUELLER/PathTools-3.40.tar.gz',
        'FILES'        => q[dist/Cwd],
        'EXCLUDED'     => [qr{^t/lib/Test/}],
        'UPSTREAM'     => "blead",

        # NOTE: PathTools is in dist/Cwd/ instead of dist/PathTools because it
        # contains Cwd.xs and something, possibly Makefile.SH, makes an assumption
        # that the leafname of some file corresponds with the pathname of the
        # directory.
    },

    'Perl::OSType' => {
        'DISTRIBUTION' => 'DAGOLDEN/Perl-OSType-1.006.tar.gz',
        'FILES'        => q[cpan/Perl-OSType],
        'EXCLUDED'     => [qw(cpanfile), qw(tidyall.ini), qr/^xt/, qr{^t/00-}],
        'UPSTREAM'     => 'cpan',
    },

    'perldtrace' => {
        'MAINTAINER' => 'SARTAK',
        'FILES'      => q[pod/perldtrace.pod],
        'UPSTREAM'   => 'blead',
    },

    'perlebcdic' => {
        'MAINTAINER' => 'PVHP',
        'FILES'      => q[pod/perlebcdic.pod],
        'UPSTREAM'   => undef,
    },

    'perlfaq' => {
        'DISTRIBUTION' => 'LLAP/perlfaq-5.0150044.tar.gz',
        'FILES'        => q[cpan/perlfaq],
        'EXCLUDED'     => [
            qw( t/release-pod-syntax.t
                t/release-eol.t
                t/release-no-tabs.t
                )
        ],
        'UPSTREAM' => 'cpan',
    },

    'PerlIO' => {
        'FILES'      => q[lib/PerlIO.pm],
        'UPSTREAM'   => undef,
    },

    'PerlIO::encoding' => {
        'FILES'      => q[ext/PerlIO-encoding],
        'UPSTREAM'   => 'blead',
    },

    'PerlIO::mmap' => {
        'FILES'      => q[ext/PerlIO-mmap],
        'UPSTREAM'   => 'blead',
    },

    'PerlIO::scalar' => {
        'FILES'      => q[ext/PerlIO-scalar],
        'UPSTREAM'   => 'blead',
    },

    'PerlIO::via' => {
        'FILES'      => q[ext/PerlIO-via],
        'UPSTREAM'   => 'blead',
    },

    'PerlIO::via::QuotedPrint' => {
        'DISTRIBUTION' => 'ELIZABETH/PerlIO-via-QuotedPrint-0.07.tar.gz',
        'FILES'        => q[cpan/PerlIO-via-QuotedPrint],

        # Waiting to be merged upstream: see CPAN RT#54047
        'CUSTOMIZED'   => [
            qw( t/QuotedPrint.t
                ),
        ],

        'UPSTREAM'     => undef,
    },

    'perlpacktut' => {
        'MAINTAINER' => 'laun',
        'FILES'      => q[pod/perlpacktut.pod],
        'UPSTREAM'   => undef,
    },

    'perlpodspec' => {
        'MAINTAINER' => 'SBURKE',
        'FILES'      => q[pod/perlpodspec.pod],
        'UPSTREAM'   => undef,
    },

    'perlre' => {
        'MAINTAINER' => 'ABIGAIL',
        'FILES'      => q[pod/perlrecharclass.pod
                 pod/perlrebackslash.pod],
        'UPSTREAM' => undef,
    },

    'perlreapi' => {
        'MAINTAINER' => 'AVAR',
        'FILES'      => q[pod/perlreapi.pod],
        'UPSTREAM'   => undef,
    },

    'perlreftut' => {
        'MAINTAINER' => 'MJD',
        'FILES'      => q[pod/perlreftut.pod],
        'UPSTREAM'   => 'blead',
    },

    'perlthrtut' => {
        'MAINTAINER' => 'ELIZABETH',
        'FILES'      => q[pod/perlthrtut.pod],
        'UPSTREAM'   => undef,
    },

    'Pod::Checker' => {
        'DISTRIBUTION' => 'MAREKR/Pod-Checker-1.60.tar.gz',
        'FILES'        => q[cpan/Pod-Checker],
        'UPSTREAM'     => 'cpan',
    },

    'Pod::Escapes' => {
        'DISTRIBUTION' => 'SBURKE/Pod-Escapes-1.04.tar.gz',
        'FILES'        => q[cpan/Pod-Escapes],
        'UPSTREAM'     => undef,
    },

    'Pod::Functions' => {
        'FILES'      => q[ext/Pod-Functions],
        'UPSTREAM'   => 'blead',
    },

    'Pod::Html' => {
        'FILES'      => q[ext/Pod-Html],
        'UPSTREAM'   => 'blead',
    },

    'Pod::Parser' => {
        'DISTRIBUTION' => 'MAREKR/Pod-Parser-1.61.tar.gz',
        'FILES'        => q[cpan/Pod-Parser],
        'UPSTREAM'     => 'cpan',
    },

    'Pod::Perldoc' => {
        'DISTRIBUTION' => 'MALLEN/Pod-Perldoc-3.20.tar.gz',
        'FILES'        => q[cpan/Pod-Perldoc],

        # in blead, the perldoc executable is generated by perldoc.PL
        # instead
        # XXX We can and should fix this, but clean up the DRY-failure in utils
        # first
        'EXCLUDED' => ['perldoc'],
        'UPSTREAM' => 'cpan',
    },

    'Pod::Simple' => {
        'DISTRIBUTION' => 'DWHEELER/Pod-Simple-3.28.tar.gz',
        'FILES'        => q[cpan/Pod-Simple],
        'UPSTREAM'     => 'cpan',
    },

    'Pod::Usage' => {
        'DISTRIBUTION' => 'MAREKR/Pod-Usage-1.63.tar.gz',
        'FILES'        => q[cpan/Pod-Usage],
        'UPSTREAM'     => 'cpan',
    },

    'podlators' => {
        'DISTRIBUTION' => 'RRA/podlators-2.5.2.tar.gz',
        'FILES'        => q[cpan/podlators pod/perlpodstyle.pod],

        # The perl distribution has pod2man.PL and pod2text.PL,  which are
        # run to create pod2man and pod2text, while the CPAN distribution
        # just has the post-generated pod2man and pod2text files.
        # The following entries attempt to codify that odd fact.
        'CUSTOMIZED' => [
            qw( scripts/pod2man.PL
                scripts/pod2text.PL
                ),
        ],
        'MAP' => {
            ''                 => 'cpan/podlators/',
            'scripts/pod2man'  => 'cpan/podlators/scripts/pod2man.PL',
            'scripts/pod2text' => 'cpan/podlators/scripts/pod2text.PL',

            # this file lives outside the cpan/ directory
            'pod/perlpodstyle.pod' => 'pod/perlpodstyle.pod',
        },
        'UPSTREAM' => 'cpan',
    },

    'POSIX' => {
        'FILES'      => q[ext/POSIX],
        'UPSTREAM'   => 'blead',
    },

    're' => {
        'FILES'      => q[ext/re],
        'UPSTREAM'   => 'blead',
    },

    's2p' => {
        'MAINTAINER' => 'laun',
        'FILES'      => q[x2p/s2p.PL],
        'UPSTREAM'   => undef,
    },

    'Safe' => {
        'DISTRIBUTION' => 'RGARCIA/Safe-2.35.tar.gz',
        'FILES'        => q[dist/Safe],
        'UPSTREAM'     => 'blead',
    },

    'Scalar-List-Utils' => {
        'DISTRIBUTION' => 'PEVANS/Scalar-List-Utils-1.32.tar.gz',
        'FILES'    => q[cpan/List-Util],
        'EXCLUDED' => [
            qr{^inc/Module/},
            qr{^inc/Test/},
            'mytypemap',
        ],
        'UPSTREAM' => 'cpan',
    },

    'SDBM_File' => {
        'FILES'      => q[ext/SDBM_File],
        'UPSTREAM'   => 'blead',
    },

    'Search::Dict' => {
        'DISTRIBUTION' => 'DAGOLDEN/Search-Dict-1.07.tar.gz',
        'FILES'        => q[dist/Search-Dict],
        'EXCLUDED'     => [qr{^t/release-.*\.t},qr{^README\..*}],
        'UPSTREAM'     => 'blead',
    },

    'SelfLoader' => {
        'DISTRIBUTION' => 'SMUELLER/SelfLoader-1.20.tar.gz',
        'FILES'        => q[dist/SelfLoader],
        'EXCLUDED'     => ['t/00pod.t'],
        'UPSTREAM'     => 'blead',
    },

    'sigtrap' => {
        'FILES'      => q[lib/sigtrap.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Socket' => {
        'DISTRIBUTION' => 'PEVANS/Socket-2.012.tar.gz',
        'FILES'        => q[cpan/Socket],
        'UPSTREAM'     => 'cpan',
    },

    'Storable' => {
        'DISTRIBUTION' => 'AMS/Storable-2.45.tar.gz',
        'FILES'        => q[dist/Storable],
        'EXCLUDED'     => [qr{^t/Test/}],
        'UPSTREAM'     => 'blead',
    },

    'Sys::Hostname' => {
        'FILES'      => q[ext/Sys-Hostname],
        'UPSTREAM'   => 'blead',
    },

    'Sys::Syslog' => {
        'DISTRIBUTION' => 'SAPER/Sys-Syslog-0.33.tar.gz',
        'FILES'        => q[cpan/Sys-Syslog],
        'EXCLUDED'     => [
            qr{^eg/},
            qw( t/data-validation.t
                t/distchk.t
                t/pod.t
                t/podcover.t
                t/podspell.t
                t/portfs.t
                win32/PerlLog.RES
                ),
        ],
        'UPSTREAM'   => 'cpan',
    },

    'Term::ANSIColor' => {
        'DISTRIBUTION' => 'RRA/Term-ANSIColor-4.02.tar.gz',
        'FILES'        => q[cpan/Term-ANSIColor],
        'EXCLUDED'     => [
            qr{^tests/},
            qr{^examples/},
            qr{^t/data/},
            qw( t/aliases-env.t
                t/critic.t
                t/minimum-version.t
                t/pod-spelling.t
                t/pod-coverage.t
                t/pod.t
                t/strict.t
                t/synopsis.t
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'Term::Cap' => {
        'DISTRIBUTION' => 'JSTOWE/Term-Cap-1.12.tar.gz',
        'FILES'        => q[cpan/Term-Cap],

        # Waiting to be merged upstream: see CPAN RT#73447
        'CUSTOMIZED'   => [
            qw( Cap.pm
                test.pl
                ),
        ],

        'UPSTREAM'     => undef,
    },

    'Term::Complete' => {
        'DISTRIBUTION' => 'FLORA/Term-Complete-1.402.tar.gz',
        'FILES'        => q[dist/Term-Complete],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'Term::ReadLine' => {
        'DISTRIBUTION' => 'FLORA/Term-ReadLine-1.14.tar.gz',
        'FILES'        => q[dist/Term-ReadLine],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'Test' => {
        'DISTRIBUTION' => 'JESSE/Test-1.26.tar.gz',
        'FILES'        => q[cpan/Test],
        'UPSTREAM'     => 'cpan',
    },

    'Test::Harness' => {
        'DISTRIBUTION' => 'OVID/Test-Harness-3.28.tar.gz',
        'FILES'        => q[cpan/Test-Harness],
        'EXCLUDED'     => [
            qr{^examples/},
            qr{^inc/},
            qr{^t/lib/Test/},
            qr{^xt/},
            qw( Changes-2.64
                NotBuild.PL
                HACKING.pod
                perlcriticrc
                t/lib/if.pm
                ),
        ],

        # Waiting to be merged upstream: see CPAN RT#64353
        'CUSTOMIZED' => [ 't/source.t' ],

        'UPSTREAM'   => 'cpan',
    },

    'Test::Simple' => {
        'DISTRIBUTION' => 'MSCHWERN/Test-Simple-0.98.tar.gz',
        'FILES'        => q[cpan/Test-Simple],
        'EXCLUDED'     => [
            qw( .perlcriticrc
                .perltidyrc
                t/00compile.t
                t/pod.t
                t/pod-coverage.t
                t/Builder/reset_outputs.t
                lib/Test/Builder/IO/Scalar.pm
                ),
        ],

        'CUSTOMIZED'   => [
            # Waiting to be merged upstream: see CPAN RT#79762
            't/fail-more.t',

            # Waiting to be merged upstream: see PERL RT#119825
            'lib/Test/Builder.pm',
            'lib/Test/Builder/Module.pm',
            'lib/Test/More.pm',
            'lib/Test/Simple.pm',
        ],

        'UPSTREAM' => 'cpan',
    },

    'Text::Abbrev' => {
        'DISTRIBUTION' => 'FLORA/Text-Abbrev-1.02.tar.gz',
        'FILES'        => q[dist/Text-Abbrev],
        'EXCLUDED'     => [qr{^t/release-.*\.t}],
        'UPSTREAM'     => 'blead',
    },

    'Text::Balanced' => {
        'DISTRIBUTION' => 'ADAMK/Text-Balanced-2.02.tar.gz',
        'FILES'        => q[cpan/Text-Balanced],
        'EXCLUDED'     => [
            qw( t/97_meta.t
                t/98_pod.t
                t/99_pmv.t
                ),
        ],

        # Waiting to be merged upstream: see CPAN RT#87788
        'CUSTOMIZED'   => [
            qw( t/01_compile.t
                t/02_extbrk.t
                t/03_extcbk.t
                t/04_extdel.t
                t/05_extmul.t
                t/06_extqlk.t
                t/07_exttag.t
                t/08_extvar.t
                t/09_gentag.t
                ),
        ],

        'UPSTREAM' => 'cpan',
    },

    'Text::ParseWords' => {
        'DISTRIBUTION' => 'CHORNY/Text-ParseWords-3.29.tar.gz',
        'FILES'        => q[cpan/Text-ParseWords],
        'EXCLUDED'     => ['t/pod.t'],

        # Waiting to be merged upstream: see CPAN RT#50929
        'CUSTOMIZED'   => [
            qw( t/ParseWords.t
                t/taint.t
                ),
        ],

        # For the benefit of make_ext.pl, we have to have this accessible:
        'MAP' => {
            'ParseWords.pm' => 'cpan/Text-ParseWords/lib/Text/ParseWords.pm',
            ''              => 'cpan/Text-ParseWords/',
        },
        'UPSTREAM' => undef,
    },

    'Text-Tabs+Wrap' => {
        'DISTRIBUTION' => 'MUIR/modules/Text-Tabs+Wrap-2013.0523.tar.gz',
        'FILES'        => q[cpan/Text-Tabs],
        'EXCLUDED'   => [
            qr/^lib\.old/,
            't/dnsparks.t',    # see af6492bf9e
        ],
        'MAP'          => {
            ''                        => 'cpan/Text-Tabs/',
            'lib.modern/Text/Tabs.pm' => 'cpan/Text-Tabs/lib/Text/Tabs.pm',
            'lib.modern/Text/Wrap.pm' => 'cpan/Text-Tabs/lib/Text/Wrap.pm',
        },
        'UPSTREAM'   => 'cpan',
    },

    'Thread::Queue' => {
        'DISTRIBUTION' => 'JDHEDDEN/Thread-Queue-3.02.tar.gz',
        'FILES'        => q[dist/Thread-Queue],
        'EXCLUDED'     => [
            qr{^examples/},
            qw( t/00_load.t
                t/99_pod.t
                t/test.pl
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Thread::Semaphore' => {
        'DISTRIBUTION' => 'JDHEDDEN/Thread-Semaphore-2.12.tar.gz',
        'FILES'        => q[dist/Thread-Semaphore],
        'EXCLUDED'     => [
            qw( examples/semaphore.pl
                t/00_load.t
                t/99_pod.t
                t/test.pl
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'threads' => {
        'DISTRIBUTION' => 'JDHEDDEN/threads-1.89.tar.gz',
        'FILES'        => q[dist/threads],
        'EXCLUDED'     => [
            qr{^examples/},
            qw( t/pod.t
                t/test.pl
                threads.h
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'threads::shared' => {
        'DISTRIBUTION' => 'JDHEDDEN/threads-shared-1.43.tar.gz',
        'FILES'        => q[dist/threads-shared],
        'EXCLUDED'     => [
            qw( examples/class.pl
                shared.h
                t/pod.t
                t/test.pl
                ),
        ],
        'UPSTREAM' => 'blead',
    },

    'Tie::File' => {
        'DISTRIBUTION' => 'TODDR/Tie-File-0.98.tar.gz',
        'FILES'        => q[dist/Tie-File],
        'UPSTREAM'     => 'blead',
    },

    'Tie::Hash' => {
        'FILES'      => q[lib/Tie/Hash.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'Tie::Hash::NamedCapture' => {
        'FILES'      => q[ext/Tie-Hash-NamedCapture],
        'UPSTREAM'   => 'blead',
    },

    'Tie::Memoize' => {
        'FILES'      => q[ext/Tie-Memoize],
        'UPSTREAM'   => 'blead',
    },

    'Tie::RefHash' => {
        'DISTRIBUTION' => 'FLORA/Tie-RefHash-1.39.tar.gz',
        'FILES'        => q[cpan/Tie-RefHash],
        'UPSTREAM'     => 'cpan',
    },

    'Time::HiRes' => {
        'DISTRIBUTION' => 'ZEFRAM/Time-HiRes-1.9726.tar.gz',
        'FILES'        => q[cpan/Time-HiRes],
        'UPSTREAM'     => 'cpan',
    },

    'Time::Local' => {
        'DISTRIBUTION' => 'DROLSKY/Time-Local-1.2300.tar.gz',
        'FILES'        => q[cpan/Time-Local],
        'EXCLUDED'     => [
            qw( t/pod-coverage.t
                t/pod.t
                ),
            qr{^t/release-.*\.t},
        ],
        'UPSTREAM' => 'cpan',
    },

    'Time::Piece' => {
        'DISTRIBUTION' => 'RJBS/Time-Piece-1.23.tar.gz',
        'FILES'        => q[cpan/Time-Piece],
        'UPSTREAM'     => undef,
    },

    'Unicode::Collate' => {
        'DISTRIBUTION' => 'SADAHIRO/Unicode-Collate-0.99.tar.gz',
        'FILES'        => q[cpan/Unicode-Collate],
        'EXCLUDED'     => [
            qr{N$},
            qr{^data/},
            qr{^gendata/},
            qw( disableXS
                enableXS
                mklocale
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'Unicode::Normalize' => {
        'DISTRIBUTION' => 'SADAHIRO/Unicode-Normalize-1.16.tar.gz',
        'FILES'        => q[cpan/Unicode-Normalize],
        'EXCLUDED'     => [
            qw( MANIFEST.N
                Normalize.pmN
                disableXS
                enableXS
                ),
        ],
        'UPSTREAM' => 'cpan',
    },

    'Unicode::UCD' => {
        'FILES'      => q[lib/Unicode/UCD.{pm,t}],
        'UPSTREAM'   => 'blead',
    },

    'version' => {
        'DISTRIBUTION' => 'JPEACOCK/version-0.9904.tar.gz',
        'FILES'        => q[cpan/version],
        'EXCLUDED' => [
            qr{^vutil/},
            'lib/version/typemap',
            't/survey_locales',
            'vperl/vpp.pm',
        ],

        # Waiting to be merged upstream: see CPAN RT#87513
        'CUSTOMIZED'   => [
            qw( lib/version.pm
                t/07locale.t
                t/08_corelist.t
                ),
        ],

        'UPSTREAM' => undef,
    },

    'vms' => {
        'MAINTAINER' => 'CBERRY',
        'FILES'      => q[vms configure.com README.vms],
        'UPSTREAM'   => undef,
    },

    'VMS::DCLsym' => {
        'MAINTAINER' => 'CBERRY',
        'FILES'      => q[ext/VMS-DCLsym],
        'UPSTREAM'   => undef,
    },

    'VMS::Filespec' => {
        'FILES'      => q[ext/VMS-Filespec],
        'UPSTREAM'   => undef,
    },

    'VMS::Stdio' => {
        'MAINTAINER' => 'CBERRY',
        'FILES'      => q[ext/VMS-Stdio],
        'UPSTREAM'   => undef,
    },

    'warnings' => {
        'MAINTAINER' => 'PMQS',
        'FILES'      => q[regen/warnings.pl
                 lib/warnings.{pm,t}
                 lib/warnings
                 t/lib/warnings
                ],
        'UPSTREAM' => 'blead',
    },

    'win32' => {
        'MAINTAINER' => 'JDB',
        'FILES'      => q[win32 t/win32 README.win32 ext/Win32CORE],
        'UPSTREAM'   => undef,
    },

    'Win32' => {
        'DISTRIBUTION' => "JDB/Win32-0.47.tar.gz",
        'FILES'        => q[cpan/Win32],
        'UPSTREAM'     => 'cpan',
    },

    'Win32API::File' => {
        'DISTRIBUTION' => 'CHORNY/Win32API-File-0.1201.tar.gz',
        'FILES'        => q[cpan/Win32API-File],
        'EXCLUDED'     => [
            qr{^ex/},
            't/pod.t',
        ],
        'UPSTREAM' => 'cpan',
    },

    'XS::Typemap' => {
        'FILES'      => q[ext/XS-Typemap],
        'UPSTREAM'   => 'blead',
    },

    'XSLoader' => {
        'DISTRIBUTION' => 'SAPER/XSLoader-0.16.tar.gz',
        'FILES'        => q[dist/XSLoader],
        'EXCLUDED'     => [
            qr{^eg/},
            qw( t/00-load.t
                t/01-api.t
                t/distchk.t
                t/pod.t
                t/podcover.t
                t/portfs.t
                ),
            'XSLoader.pm',    # we use XSLoader_pm.PL
        ],
        # Revert UPSTREAM to 'blead' after 0.17 is released
        'UPSTREAM' => undef,
    },

    # this pseudo-module represents all the files under ext/ and lib/
    # that aren't otherwise claimed. This means that the following two
    # commands will check that every file under ext/ and lib/ is
    # accounted for, and that there are no duplicates:
    #
    #    perl Porting/Maintainers --checkmani lib ext
    #    perl Porting/Maintainers --checkmani

    '_PERLLIB' => {
        'FILES'      => q[
                ext/arybase/
                ext/ExtUtils-Miniperl/
                ext/XS-APItest/
                lib/CORE.pod
                lib/Config.t
                lib/Config/Extensions.{pm,t}
                lib/DB.{pm,t}
                lib/ExtUtils/Embed.pm
                lib/ExtUtils/XSSymSet.pm
                lib/ExtUtils/t/Embed.t
                lib/ExtUtils/typemap
                lib/Internals.t
                lib/Net/hostent.{pm,t}
                lib/Net/netent.{pm,t}
                lib/Net/protoent.{pm,t}
                lib/Net/servent.{pm,t}
                lib/Pod/t/InputObjects.t
                lib/Pod/t/Select.t
                lib/Pod/t/Usage.t
                lib/Pod/t/utils.t
                lib/SelectSaver.{pm,t}
                lib/Symbol.{pm,t}
                lib/Thread.{pm,t}
                lib/Tie/Array.pm
                lib/Tie/Array/
                lib/Tie/ExtraHash.t
                lib/Tie/Handle.pm
                lib/Tie/Handle/
                lib/Tie/Scalar.{pm,t}
                lib/Tie/StdHandle.pm
                lib/Tie/SubstrHash.{pm,t}
                lib/Time/gmtime.{pm,t}
                lib/Time/localtime.{pm,t}
                lib/Time/tm.pm
                lib/UNIVERSAL.pm
                lib/Unicode/README
                lib/User/grent.{pm,t}
                lib/User/pwent.{pm,t}
                lib/blib.{pm,t}
                lib/bytes.{pm,t}
                lib/bytes_heavy.pl
                lib/_charnames.pm
                lib/charnames.{pm,t}
                lib/dbm_filter_util.pl
                lib/deprecate.pm
                lib/dumpvar.{pl,t}
                lib/feature.{pm,t}
                lib/feature/
                lib/filetest.{pm,t}
                lib/h2ph.t
                lib/h2xs.t
                lib/integer.{pm,t}
                lib/less.{pm,t}
                lib/locale.{pm,t}
                lib/open.{pm,t}
                lib/overload/numbers.pm
                lib/overloading.{pm,t}
                lib/perl5db.{pl,t}
                lib/perl5db/
                lib/sort.{pm,t}
                lib/strict.{pm,t}
                lib/subs.{pm,t}
                lib/unicore/
                lib/utf8.{pm,t}
                lib/utf8_heavy.pl
                lib/vars{.pm,.t,_carp.t}
                lib/vmsish.{pm,t}
                ],
        'UPSTREAM' => 'blead',
    },
);

# legacy CPAN flag
for ( values %Modules ) {
    $_->{CPAN} = !!$_->{DISTRIBUTION};
}

# legacy MAINTAINER field
for ( values %Modules ) {
    next if exists $_->{MAINTAINER};
    if (not exists $_->{DISTRIBUTION} or (defined $_->{UPSTREAM} and $_->{UPSTREAM} eq 'blead')) {
        $_->{MAINTAINER} = 'P5P';
        $Maintainers{P5P} = 'perl5-porters <perl5-porters@perl.org>';
    }
    else {
        (my $pause_id = $_->{DISTRIBUTION}) =~ s{/.*$}{};
        $_->{MAINTAINER} = $pause_id;
        $Maintainers{$pause_id} = "<$pause_id\@cpan.org>";
    }
}

1;
