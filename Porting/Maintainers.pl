# A simple listing of core files that have specific maintainers,
# or at least someone that can be called an "interested party".
# Also, a "module" does not necessarily mean a CPAN module, it
# might mean a file or files or a subdirectory.
# Most (but not all) of the modules have dual lives in the core
# and in CPAN.  Those that have a CPAN existence, have the CPAN
# attribute set to true.

package Maintainers;

%Maintainers =
    (
    'abergman'	=> 'Arthur Bergman <abergman@cpan.org>',
    'abigail'	=> 'Abigail <abigail@abigail.be>',
    'ams'	=> 'Abhijit Menon-Sen <ams@cpan.org>',
    'andk'	=> 'Andreas J. Koenig <andk@cpan.org>',
    'andya'	=> 'Andy Armstrong <andy@hexten.net>',
    'arandal'	=> 'Allison Randal <allison@perl.org>',
    'audreyt'	=> 'Audrey Tang <cpan@audreyt.org>',
    'avar'	=> 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
    'bingos'	=> 'Chris Williams <chris@bingosnet.co.uk>',
    'chorny'	=> "Alexandr Ciornii <alexchorny\100gmail.com>",
    'corion'	=> 'Max Maischein <corion@corion.net>',
    'craig'	=> 'Craig Berry <craigberry@mac.com>',
    'dankogai'	=> 'Dan Kogai <dankogai@cpan.org>',
    'dconway'	=> 'Damian Conway <dconway@cpan.org>',
    'dland'	=> 'David Landgren <dland@cpan.org>',
    'dmanura'	=> 'David Manura <dmanura@cpan.org>',
    'drolsky'	=> 'Dave Rolsky <drolsky@cpan.org>',
    'elizabeth'	=> 'Elizabeth Mattijsen <liz@dijkmat.nl>',
    'ferreira'	=> 'Adriano Ferreira <ferreira@cpan.org>',
    'gbarr'	=> 'Graham Barr <gbarr@cpan.org>',
    'gaas'	=> 'Gisle Aas <gaas@cpan.org>',
    'gsar'	=> 'Gurusamy Sarathy <gsar@activestate.com>',
    'ilyam'	=> 'Ilya Martynov <ilyam@cpan.org>',
    'ilyaz'	=> 'Ilya Zakharevich <ilyaz@cpan.org>',
    'jand'	=> 'Jan Dubois <jand@activestate.com>',
    'jdhedden'	=> 'Jerry D. Hedden <jdhedden@cpan.org>',
    'jhi'	=> 'Jarkko Hietaniemi <jhi@cpan.org>',
    'jjore'	=> 'Joshua ben Jore <jjore@cpan.org>',
    'jpeacock'	=> 'John Peacock <jpeacock@rowman.com>',
    'jstowe'	=> 'Jonathan Stowe <jstowe@cpan.org>',
    'jv'	=> 'Johan Vromans <jv@cpan.org>',
    'kane'	=> 'Jos Boumans <kane@cpan.org>',
    'kwilliams'	=> 'Ken Williams <kwilliams@cpan.org>',
    'laun'	=> 'Wolfgang Laun <Wolfgang.Laun@alcatel.at>',
    'lstein'	=> 'Lincoln D. Stein <lds@cpan.org>',
    'lwall'	=> 'Larry Wall <lwall@cpan.org>',
    'marekr'	=> 'Marek Rouchal <marekr@cpan.org>',
    'markm'	=> 'Mark Mielke <markm@cpan.org>',
    'mhx'	=> 'Marcus Holland-Moritz <mhx@cpan.org>',
    'mjd'	=> 'Mark-Jason Dominus <mjd@plover.com>',
    'msergeant'	=> 'Matt Sergeant <msergeant@cpan.org>',
    'mshelor'	=> 'Mark Shelor <mshelor@cpan.org>',
    'muir'	=> 'David Muir Sharnoff <muir@cpan.org>',
    'neilb'	=> 'Neil Bowers <neilb@cpan.org>',
    'nuffin'	=> 'Yuval Kogman <nothingmuch@woobling.org>',
    'nwclark'	=> 'Nicholas Clark <nwclark@cpan.org>',
    'osfameron'	=> 'Hakim Cassimally <osfameron@perl.org>',
    'p5p'	=> 'perl5-porters <perl5-porters@perl.org>',
    'perlfaq'	=> 'perlfaq-workers <perlfaq-workers@perl.org>',
    'petdance'	=> 'Andy Lester <andy@petdance.com>',
    'pjf'	=> 'Paul Fenwick <pjf@cpan.org>',
    'pmqs'	=> 'Paul Marquess <pmqs@cpan.org>',
    'pvhp'	=> 'Peter Prymmer <pvhp@best.com>',
    'rafl'	=> 'Florian Ragwitz <flora@cpan.org>',
    'rclamp'	=> 'Richard Clamp <rclamp@cpan.org>',
    'rgarcia'	=> 'Rafael Garcia-Suarez <rgarcia@cpan.org>',
    'rkobes'	=> 'Randy Kobes <rkobes@cpan.org>',
    'rmbarker'	=> 'Robin Barker <rmbarker@cpan.org>',
    'rra'	=> 'Russ Allbery <rra@cpan.org>',
    'rurban'	=> 'Reini Urban <rurban@cpan.org>',
    'sadahiro'	=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'salva'	=> 'Salvador Fandiño García <salva@cpan.org>',
    'saper'	=> 'Sébastien Aperghis-Tramoni <saper@cpan.org>',
    'sburke'	=> 'Sean Burke <sburke@cpan.org>',
    'mschwern'	=> 'Michael Schwern <mschwern@cpan.org>',
    'simonw'	=> 'Simon Wistow <simonw@cpan.org>',
    'smccam'	=> 'Stephen McCamant <smccam@cpan.org>',
    'smpeters'	=> 'Steve Peters <steve@fisharerojo.org>',
    'smueller'	=> 'Steffen Mueller <smueller@cpan.org>',
    'tels'	=> 'Tels <nospam-abuse@bloodgate.com>',
    'tomhughes'	=> 'Tom Hughes <tomhughes@cpan.org>',
    'tjenness'	=> 'Tim Jenness <tjenness@cpan.org>',
    'tyemq'	=> 'Tye McQueen <tyemq@cpan.org>',
    'yves'	=> 'Yves Orton <yves@cpan.org>',
    'zefram'	=> 'Andrew Main <zefram@cpan.org>',
    );

# Each entry in the  %Modules hash roughly represents a distribution,
# except in the case of CPAN=1, where it *exactly* represents a single
# CPAN distribution.

# The keys of %Modules are human descriptions of the distributions, and
# may not exactly match a module or distribution name. Distributions
# which have an obvious top-level module associated with them will usually
# have a key named for that module, e.g. 'Archive::Extract' for
# Archive-Extract-N.NN.tar.gz; the remaining keys are likely to be based
# on the name of the distribution, e.g. 'Locale-Codes' for
# Locale-Codes-N.NN.tar.gz'.
#
# FILES is a list of filenames, glob patterns, and directory
# names to be recursed down, which collectively generate a complete list
# of the files associated with the distribution.

# CPAN can be either 1 (this distribution is also available on CPAN),
# or 0 (there is no # valid CPAN release).

# UPSTREAM indicates where patches should go. undef implies
# that this hasn't been discussed for the module at hand.
# "blead" indicates that the copy of the module in the blead
# sources is to be considered canonical, "cpan" means that the
# module on CPAN is to be patched first. "first-come" means
# that blead can be patched freely if it is in sync with the
# latest release on CPAN.

# DISTRIBUTION names the tarball on CPAN which (allegedly) the files
# included in core are derived from. Note that the file's version may not
# necessarily match the newest version on CPAN.

%Modules = (

    'Archive::Extract' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Archive-Extract-0.30.tar.gz',
	'FILES'		=> q[lib/Archive/Extract.pm lib/Archive/Extract],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Archive::Tar' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Archive-Tar-1.48.tar.gz',
	'FILES'		=> q[lib/Archive/Tar.pm lib/Archive/Tar],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Attribute::Handlers' =>
	{
	'MAINTAINER'	=> 'rgarcia',
	'DISTRIBUTION'	=> 'SMUELLER/Attribute-Handlers-0.83.tar.gz',
	'FILES'		=> q[ext/Attribute-Handlers],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'autodie' =>
	{
	'MAINTAINER'	=> 'pjf',
	'DISTRIBUTION'	=> 'PJF/autodie-1.999.tar.gz',
	'FILES' 	=> q[lib/Fatal.pm lib/autodie.pm lib/autodie],
	'CPAN'  	=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'AutoLoader' =>
	{
	'MAINTAINER'	=> 'smueller',
	'DISTRIBUTION'	=> 'SMUELLER/AutoLoader-5.68.tar.gz',
	'FILES'		=> q[lib/AutoLoader.pm lib/AutoSplit.pm lib/AutoLoader],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "cpan",
	},

    'B::Concise' =>
	{
	'MAINTAINER'	=> 'smccam',
	'FILES'		=> q[ext/B/B/Concise.pm ext/B/t/concise.t],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'B::Debug' =>
	{
	'MAINTAINER'	=> 'rurban',
	'DISTRIBUTION'	=> 'RURBAN/B-Debug-1.11.tar.gz',
	'FILES'		=> q[ext/B/B/Debug.pm ext/B/t/debug.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'B::Deparse' =>
	{
	'MAINTAINER'	=> 'smccam',
	'FILES'		=> q[ext/B/B/Deparse.pm ext/B/t/deparse.t],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'B::Lint' =>
	{
	'MAINTAINER'	=> 'jjore',
	'DISTRIBUTION'	=> 'JJORE/B-Lint-1.11.tar.gz',
	'FILES'		=> q[ext/B/B/Lint.pm ext/B/t/lint.t
			    ext/B/B/Lint/Debug.pm
			    ext/B/t/pluglib/B/Lint/Plugin/Test.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'base' =>
	{
	'MAINTAINER'	=> 'rgarcia',
	'DISTRIBUTION'	=> 'RGARCIA/base-2.12.tar.gz',
	'FILES'		=> q[lib/base.pm lib/fields.pm lib/base],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'bignum' =>
	{
	'MAINTAINER'	=> 'tels',
	'DISTRIBUTION'	=> 'TELS/math/bignum-0.23.tar.gz',
	'FILES'		=> q[lib/big{int,num,rat}.pm lib/bignum],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'CGI' =>
	{
	'MAINTAINER'	=> 'lstein',
	'DISTRIBUTION'	=> 'LDS/CGI.pm-3.43.tar.gz',
	'FILES'		=> q[lib/CGI.pm lib/CGI],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Class::ISA' =>
	{
	'MAINTAINER'	=> 'sburke',
	'DISTRIBUTION'	=> 'SBURKE/Class-ISA-0.33.tar.gz',
	'FILES'		=> q[lib/Class/ISA.pm lib/Class/ISA],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Compress::Raw::Bzip2' =>
	{
	'MAINTAINER'	=> 'pmqs',
	'DISTRIBUTION'	=> 'PMQS/Compress-Raw-Bzip2-2.019.tar.gz',
	'FILES'		=> q[ext/Compress-Raw-Bzip2],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Compress::Raw::Zlib' =>
	{
	'MAINTAINER'	=> 'pmqs',
	'DISTRIBUTION'	=> 'PMQS/Compress-Raw-Zlib-2.019.tar.gz',
	'FILES'		=> q[ext/Compress-Raw-Zlib],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'constant' =>
	{
	'MAINTAINER'	=> 'saper',
	'DISTRIBUTION'	=> 'SAPER/constant-1.17.tar.gz',
	'FILES'		=> q[lib/constant.{pm,t}],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'CPAN' =>
	{
	'MAINTAINER'	=> 'andk',
	'DISTRIBUTION'	=> 'ANDK/CPAN-1.94.tar.gz',
	'FILES'		=> q[lib/CPAN.pm lib/CPAN],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'CPAN',
	},

    'CPANPLUS' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/CPANPLUS-0.8601.tar.gz',
	'FILES'		=> q[lib/CPANPLUS.pm
			     lib/CPANPLUS/Backend lib/CPANPLUS/Backend.pm
			     lib/CPANPLUS/bin
			     lib/CPANPLUS/Config.pm
			     lib/CPANPLUS/Configure lib/CPANPLUS/Configure.pm
			     lib/CPANPLUS/Error.pm
			     lib/CPANPLUS/FAQ.pod
			     lib/CPANPLUS/Hacking.pod
			     lib/CPANPLUS/inc.pm
			     lib/CPANPLUS/Internals lib/CPANPLUS/Internals.pm
			     lib/CPANPLUS/Module lib/CPANPLUS/Module.pm
			     lib/CPANPLUS/Selfupdate.pm
			     lib/CPANPLUS/Shell lib/CPANPLUS/Shell.pm
			     lib/CPANPLUS/Dist.pm lib/CPANPLUS/Dist/Base.pm
			     lib/CPANPLUS/Dist/Autobundle.pm
			     lib/CPANPLUS/Dist/MM.pm lib/CPANPLUS/Dist/Sample.pm
			     lib/CPANPLUS/t
			    ],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'CPANPLUS::Dist::Build' =>
	{
	'MAINTAINER'	=> 'bingos',
	'DISTRIBUTION'	=> 'BINGOS/CPANPLUS-Dist-Build-0.30.tar.gz',
	'FILES'		=> q[lib/CPANPLUS/Dist/Build.pm lib/CPANPLUS/Dist/Build],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Data::Dumper' =>
	{
	'MAINTAINER'	=> 'p5p', # Not gsar. Not ilyam
	'DISTRIBUTION'	=> 'ILYAM/Data-Dumper-2.121.tar.gz',
	'FILES'		=> q[ext/Data-Dumper],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'DB_File' =>
	{
	'MAINTAINER'	=> 'pmqs',
	'DISTRIBUTION'	=> 'PMQS/DB_File-1.820.tar.gz',
	'FILES'		=> q[ext/DB_File],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Devel::PPPort' =>
	{
	'MAINTAINER'	=> 'mhx',
	'DISTRIBUTION'	=> 'MHX/Devel-PPPort-3.17.tar.gz',
	'FILES'		=> q[ext/Devel-PPPort],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Digest' =>
	{
	'MAINTAINER'	=> 'gaas',
	'DISTRIBUTION'	=> 'GAAS/Digest-1.15.tar.gz',
	'FILES'		=> q[lib/Digest.pm lib/Digest],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Digest::MD5' =>
	{
	'MAINTAINER'	=> 'gaas',
	'DISTRIBUTION'	=> 'GAAS/Digest-MD5-2.38.tar.gz',
	'FILES'		=> q[ext/Digest-MD5],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Digest::SHA' =>
	{
	'MAINTAINER'	=> 'mshelor',
	'DISTRIBUTION'	=> 'MSHELOR/Digest-SHA-5.47.tar.gz',
	'FILES' 	=> q[ext/Digest-SHA],
	'CPAN'  	=> 1,
	'UPSTREAM'	=> undef,
	},

    'Encode' =>
	{
	'MAINTAINER'	=> 'dankogai',
	'DISTRIBUTION'	=> 'DANKOGAI/Encode-2.33.tar.gz',
	'FILES'		=> q[ext/Encode],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'encoding::warnings' =>
	{
	'MAINTAINER'	=> 'audreyt',
	'DISTRIBUTION'	=> 'AUDREYT/encoding-warnings-0.11.tar.gz',
	'FILES'		=> q[lib/encoding/warnings.pm lib/encoding/warnings],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Errno' =>
	{
	'MAINTAINER'	=> 'p5p', # Not gbarr.
	'FILES'		=> q[ext/Errno],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'Exporter' =>
	{
	'MAINTAINER'	=> 'ferreira',
	'DISTRIBUTION'	=> 'FERREIRA/Exporter-5.63.tar.gz',
	'FILES'		=> q[lib/Exporter.pm lib/Exporter.t lib/Exporter/Heavy.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'ExtUtils::CBuilder' =>
	{
	'MAINTAINER'	=> 'kwilliams',
	'DISTRIBUTION'	=> 'KWILLIAMS/ExtUtils-CBuilder-0.24.tar.gz',
	'FILES'		=> q[lib/ExtUtils/CBuilder.pm lib/ExtUtils/CBuilder],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'ExtUtils::Command' =>
	{
	'MAINTAINER'	=> 'rkobes',
	'DISTRIBUTION'	=> 'RKOBES/ExtUtils-Command-1.16.tar.gz',
	'FILES'		=> q[lib/ExtUtils/Command.pm
			     lib/ExtUtils/t/{cp,eu_command}.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'ExtUtils::Constant' =>
	{
	'MAINTAINER'	=> 'nwclark',
	'DISTRIBUTION'	=> 'NWCLARK/ExtUtils-Constant-0.16.tar.gz',
	'FILES'		=> q[lib/ExtUtils/Constant.pm lib/ExtUtils/Constant
			     lib/ExtUtils/t/Constant.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'ExtUtils::Install' =>
	{
	'MAINTAINER'	=> 'yves',
	'DISTRIBUTION'	=> 'YVES/ExtUtils-Install-1.52.tar.gz',
	# MakeMaker has a basic.t too, and we use that.
	'FILES' 	=> q[lib/ExtUtils/{Install,Installed,Packlist}.pm
                             lib/ExtUtils/Changes_EU-Install
			     lib/ExtUtils/t/Installed.t
			     lib/ExtUtils/t/basic.pl
			     lib/ExtUtils/t/{Install,Installapi2,Packlist,can_write_dir}.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'ExtUtils::MakeMaker' =>
	{
	'MAINTAINER'	=> 'mschwern',
	'DISTRIBUTION'	=> 'MSCHWERN/ExtUtils-MakeMaker-6.52.tar.gz',
	'FILES'		=> q[lib/ExtUtils/{Liblist,MakeMaker,Mkbootstrap,Mksymlists,MM*,MY,testlib}.pm
			     lib/ExtUtils/{Command,Liblist,MakeMaker}
			     lib/ExtUtils/t/{[0-9FLV-Zabdf-z]*,IN*,Mkbootstrap,MM_*,PL_FILES,cd,config}.t
			     lib/ExtUtils/Changes
			     lib/ExtUtils/{NOTES,PATCHING,README,TODO}
			     lib/ExtUtils/instmodsh
			     t/lib/MakeMaker t/lib/TieIn.pm t/lib/TieOut.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'first-come',
	},

    'ExtUtils::Manifest' =>
	{
	'MAINTAINER'	=> 'rkobes',
	'DISTRIBUTION'	=> 'RKOBES/ExtUtils-Manifest-1.56.tar.gz',
	'FILES'		=> q[lib/ExtUtils/{Manifest.pm,MANIFEST.SKIP} lib/ExtUtils/t/Manifest.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'ExtUtils::ParseXS' =>
	{
	'MAINTAINER'	=> 'kwilliams',
	'DISTRIBUTION'	=> 'KWILLIAMS/ExtUtils-ParseXS-2.19.tar.gz',
	'FILES'		=> q[lib/ExtUtils/ParseXS.pm lib/ExtUtils/ParseXS],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'faq' =>
	{
	'MAINTAINER'	=> 'perlfaq',
	'FILES'		=> q[pod/perlfaq*],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'File::Fetch' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/File-Fetch-0.18.tar.gz',
	'FILES'		=> q[lib/File/Fetch.pm lib/File/Fetch],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'File::Path' =>
	{
	'MAINTAINER'	=> 'dland',
	'DISTRIBUTION'	=> 'DLAND/File-Path-2.07.tar.gz',
	'FILES'		=> q[lib/File/Path.pm lib/File/Path.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'File::Temp' =>
	{
	'MAINTAINER'	=> 'tjenness',
	'DISTRIBUTION'	=> 'TJENNESS/File-Temp-0.21.tar.gz',
	'FILES'		=> q[lib/File/Temp.pm lib/File/Temp],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Filter::Simple' =>
	{
	'MAINTAINER'	=> 'smueller',
	'DISTRIBUTION'	=> 'SMUELLER/Filter-Simple-0.84.tar.gz',
	'FILES'		=> q[lib/Filter/Simple.pm lib/Filter/Simple
			    t/lib/Filter/Simple/ ],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'Filter::Util::Call' =>
	{
	'MAINTAINER'	=> 'pmqs',
	'DISTRIBUTION'	=> 'PMQS/Filter-1.36.tar.gz',
	'FILES'		=> q[ext/Filter-Util-Call
			     t/lib/filter-util.pl],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Getopt::Long' =>
	{
	'MAINTAINER'	=> 'jv',
	'DISTRIBUTION'	=> 'JV/Getopt-Long-2.38.tar.gz',
	'FILES'		=> q[lib/Getopt/Long.pm lib/Getopt/Long],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    # Sean has donated it to us.
    # Nothing has changed since his last CPAN release.
    'I18N::LangTags' =>
	{
	'MAINTAINER'	=> 'p5p',
	'DISTRIBUTION'	=> 'SBURKE/I18N-LangTags-0.35.tar.gz',
	'FILES'		=> q[lib/I18N/LangTags.pm lib/I18N/LangTags],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'if' =>
	{
	'MAINTAINER'	=> 'ilyaz',
	'DISTRIBUTION'	=> 'ILYAZ/modules/if-0.0401.tar.gz',
	'FILES'		=> q[lib/if.{pm,t}],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'IO' =>
	{
	'MAINTAINER'	=> 'gbarr',
	'DISTRIBUTION'	=> 'GBARR/IO-1.25.tar.gz',
	'FILES'		=> q[ext/IO/],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'IO-Compress' =>
	{
	'MAINTAINER'	=> 'pmqs',
	'DISTRIBUTION'	=> 'PMQS/IO-Compress-2.019.tar.gz',
	'FILES'		=> q[ext/IO-Compress],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'IO::Zlib' =>
	{
	'MAINTAINER'	=> 'tomhughes',
	'DISTRIBUTION'	=> 'TOMHUGHES/IO-Zlib-1.09.tar.gz',
	'FILES'		=> q[lib/IO/Zlib.pm lib/IO/Zlib],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'IPC::Cmd' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/IPC-Cmd-0.44.tar.gz',
	'FILES'		=> q[lib/IPC/Cmd lib/IPC/Cmd.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'IPC::SysV' =>
	{
	'MAINTAINER'	=> 'mhx',
	'DISTRIBUTION'	=> 'MHX/IPC-SysV-2.01.tar.gz',
	'FILES'		=> q[ext/IPC-SysV],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'lib' =>
	{
	'MAINTAINER'	=> 'smueller',
	'DISTRIBUTION'	=> 'SMUELLER/lib-0.62.tar.gz',
	'FILES'		=>
		q[lib/lib_pm.PL lib/lib.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'libnet' =>
	{
	'MAINTAINER'	=> 'gbarr',
	'DISTRIBUTION'	=> 'GBARR/libnet-1.22.tar.gz',
	'FILES'		=>
		q[lib/Net/{Cmd,Config,Domain,FTP,Netrc,NNTP,POP3,SMTP,Time}.pm lib/Net/Changes lib/Net/FTP lib/Net/demos/ lib/Net/*.eg lib/Net/libnetFAQ.pod lib/Net/README lib/Net/t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Locale-Codes' =>
	{
	'MAINTAINER'	=> 'neilb',
	'DISTRIBUTION'	=> 'NEILB/Locale-Codes-2.07.tar.gz',
	'FILES'		=> q[lib/Locale/{Codes,Constants,Country,Currency,Language,Script}*],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Locale::Maketext' =>
	{
	'MAINTAINER'	=> 'ferreira',
	'DISTRIBUTION'	=> 'FERREIRA/Locale-Maketext-1.13.tar.gz',
	'FILES'		=> q[lib/Locale/Maketext.pm lib/Locale/Maketext.pod lib/Locale/Maketext/ChangeLog lib/Locale/Maketext/{Guts,GutsLoader}.pm lib/Locale/Maketext/README lib/Locale/Maketext/TPJ13.pod lib/Locale/Maketext/t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Locale::Maketext::Simple' =>
	{
	'MAINTAINER'	=> 'audreyt',
	'DISTRIBUTION'	=> 'AUDREYT/Locale-Maketext-Simple-0.18.tar.gz',
	'FILES'		=> q[lib/Locale/Maketext/Simple.pm lib/Locale/Maketext/Simple],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Log::Message' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Log-Message-0.02.tar.gz',
	'FILES'		=> q[lib/Log/Message.pm lib/Log/Message/{Config,Handlers,Item}.pm lib/Log/Message/t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Log::Message::Simple' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Log-Message-Simple-0.04.tar.gz',
	'FILES'		=> q[lib/Log/Message/Simple.pm lib/Log/Message/Simple],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'mad' =>
	{
	'MAINTAINER'	=> 'lwall',
	'FILES'		=> q[mad],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'Math::BigInt' =>
	{
	'MAINTAINER'	=> 'tels',
	'DISTRIBUTION'	=> 'TELS/math/Math-BigInt-1.89.tar.gz',
	'FILES'		=> q[lib/Math/BigInt.pm lib/Math/BigInt
			     t/lib/Math
			     lib/Math/BigFloat.pm lib/Math/BigFloat],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Math::BigInt::FastCalc' =>
	{
	'MAINTAINER'	=> 'tels',
	'DISTRIBUTION'	=> 'TELS/math/Math-BigInt-FastCalc-0.19.tar.gz',
	'FILES'		=> q[ext/Math-BigInt-FastCalc],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Math::BigRat' =>
	{
	'MAINTAINER'	=> 'tels',
	'DISTRIBUTION'	=> 'TELS/math/Math-BigRat-0.22.tar.gz',
	'FILES'		=> q[lib/Math/BigRat.pm lib/Math/BigRat],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Math::Complex' =>
	{
	'MAINTAINER'	=> 'zefram',
	'DISTRIBUTION'	=> 'JHI/Math-Complex-1.56.tar.gz',
	'FILES'		=> q[lib/Math/Complex.pm lib/Math/Complex.t
			     lib/Math/Trig.pm lib/Math/Trig.t
			     lib/Math/underbar.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Memoize' =>
	{
	'MAINTAINER'	=> 'mjd',
	'DISTRIBUTION'	=> 'MJD/Memoize-1.01.tar.gz',
	'FILES'		=> q[lib/Memoize.pm lib/Memoize],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'MIME::Base64' =>
	{
	'MAINTAINER'	=> 'gaas',
	'DISTRIBUTION'	=> 'GAAS/MIME-Base64-3.07.tar.gz',
	'FILES'		=> q[ext/MIME-Base64],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Module::Build' =>
	{
	'MAINTAINER'	=> 'kwilliams',
	'DISTRIBUTION'	=> 'EWILHELM/Module-Build-0.33.tar.gz',
	'FILES'		=> q[lib/Module/Build lib/Module/Build.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Module::CoreList' =>
	{
	'MAINTAINER'	=> 'rgarcia',
	'DISTRIBUTION'	=> 'RGARCIA/Module-CoreList-2.17.tar.gz',
	'FILES'		=> q[lib/Module/CoreList lib/Module/CoreList.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'Module::Load' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Module-Load-0.16.tar.gz',
	'FILES'		=> q[lib/Module/Load/t lib/Module/Load.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Module::Load::Conditional' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Module-Load-Conditional-0.30.tar.gz',
	'FILES'		=> q[lib/Module/Load/Conditional
			     lib/Module/Load/Conditional.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Module::Loaded' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Module-Loaded-0.02.tar.gz',
	'FILES'		=> q[lib/Module/Loaded lib/Module/Loaded.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    # NB. tests are located in t/Module_Pluggable to avoid directory
    # depth issues on VMS
    'Module::Pluggable' =>
	{
	'MAINTAINER'	=> 'simonw',
	'DISTRIBUTION'	=> 'SIMONW/Module-Pluggable-3.9.tar.gz',
	'FILES'		=> q[ext/Module-Pluggable],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Net::Ping' =>
	{
	'MAINTAINER'	=> 'smpeters',
	'DISTRIBUTION'	=> 'SMPETERS/Net-Ping-2.35.tar.gz',
	'FILES'		=> q[lib/Net/Ping.pm lib/Net/Ping],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'NEXT' =>
	{
	'MAINTAINER'	=> 'rafl',
	'DISTRIBUTION'	=> 'FLORA/NEXT-0.63.tar.gz',
	'FILES'		=> q[lib/NEXT.pm lib/NEXT],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Object::Accessor' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Object-Accessor-0.34.tar.gz',
	'FILES'		=> q[lib/Object/Accessor.pm lib/Object/Accessor],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Package::Constants' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Package-Constants-0.02.tar.gz',
	'FILES'		=> q[lib/Package/Constants lib/Package/Constants.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Params::Check' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Params-Check-0.26.tar.gz',
	'FILES'		=> q[lib/Params/Check lib/Params/Check.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'parent' =>
	{
	'MAINTAINER'	=> 'corion',
	'DISTRIBUTION'	=> 'CORION/parent-0.221.tar.gz',
	'FILES'		=> q[lib/parent lib/parent.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Parse::CPAN::Meta' =>
	{
	'MAINTAINER'	=> 'smueller',
	'DISTRIBUTION'	=> 'ADAMK/Parse-CPAN-Meta-1.39.tar.gz',
	'FILES'		=> q[lib/Parse/CPAN/Meta.pm t/lib/Parse/CPAN/Meta/Test.pm lib/Parse/CPAN/Meta],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "cpan",
	},

    'PathTools' =>
	{
	'MAINTAINER'	=> 'kwilliams',
	'DISTRIBUTION'	=> 'SMUELLER/PathTools-3.30.tar.gz',
	'FILES'		=> q[lib/File/Spec.pm lib/File/Spec
			    ext/Cwd lib/Cwd.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "cpan",
	},

    'perlebcdic' =>
	{
	'MAINTAINER'	=> 'pvhp',
	'FILES'		=> q[pod/perlebcdic.pod],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'PerlIO' =>
	{
	'MAINTAINER'	=> 'p5p',
	'FILES'		=> q[ext/PerlIO],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'PerlIO::via::QuotedPrint' =>
	{
	'MAINTAINER'	=> 'elizabeth',
	'DISTRIBUTION'	=> 'ELIZABETH/PerlIO-via-QuotedPrint-0.06.tar.gz',
	'FILES'		=> q[lib/PerlIO/via/QuotedPrint.pm
			     lib/PerlIO/via/t/QuotedPrint.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'perlpacktut' =>
	{
	'MAINTAINER'	=> 'laun',
	'FILES'		=> q[pod/perlpacktut.pod],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'perlpodspec' =>
	{
	'MAINTAINER'	=> 'sburke',
	'FILES'		=> q[pod/perlpodspec.pod],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'perlre' =>
	{
	'MAINTAINER'	=> 'abigail',
	'FILES'		=> q[pod/perlrecharclass.pod
			     pod/perlrebackslash.pod],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},


    'perlreapi' =>
	{
	MAINTAINER	=> 'avar',
	FILES		=> 'pod/perlreapi.pod',
	CPAN		=> 0,
	'UPSTREAM'	=> undef,
	},

    'perlreftut' =>
	{
	'MAINTAINER'	=> 'mjd',
	'FILES'		=> q[pod/perlreftut.pod],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'perlthrtut' =>
	{
	'MAINTAINER'	=> 'elizabeth',
	'FILES'		=> q[pod/perlthrtut.pod],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'Pod::Escapes' =>
	{
	'MAINTAINER'	=> 'sburke',
	'DISTRIBUTION'	=> 'SBURKE/Pod-Escapes-1.04.tar.gz',
	'FILES'		=> q[lib/Pod/Escapes.pm lib/Pod/Escapes],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Pod::LaTeX' =>
	{
	'MAINTAINER'	=> 'tjenness',
	'DISTRIBUTION'	=> 'TJENNESS/Pod-LaTeX-0.58.tar.gz',
	'FILES'		=> q[lib/Pod/LaTeX.pm lib/Pod/t/{pod2latex,user}.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Pod::Parser'	=> {
	'MAINTAINER'	=> 'marekr',
	'DISTRIBUTION'	=> 'MAREKR/Pod-Parser-1.38.tar.gz',
	'FILES'		=> q[lib/Pod/{Checker,Find,InputObjects,Parser,ParseUtils,PlainText,Select,Usage}.pm lib/Pod/t/contains_pod.t pod/pod{2usage,checker,select}.PL t/lib/contains_bad_pod.xr t/lib/contains_pod.xr t/pod/emptycmd.* t/pod/find.t t/pod/for.* t/pod/headings.* t/pod/include.* t/pod/included.* t/pod/lref.* t/pod/multiline_items.* t/pod/nested_items.* t/pod/nested_seqs.* t/pod/oneline_cmds.* t/pod/pod2usage.* t/pod/podchkenc.* t/pod/poderrs.* t/pod/podselect.* t/pod/special_seqs.* t/pod/testcmp.pl t/pod/testp2pt.pl t/pod/testpchk.pl t/pod/usage*.pod],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Pod::Perldoc' =>
	{
	'MAINTAINER'	=> 'ferreira',
	'DISTRIBUTION'	=> 'FERREIRA/Pod-Perldoc-3.15.tar.gz',
	'FILES'		=> q[lib/Pod/Perldoc.pm lib/Pod/Perldoc],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Pod::Plainer' =>
	{
	'MAINTAINER'	=> 'rmbarker',
	'FILES'		=> q[lib/Pod/Plainer.pm t/pod/plainer.t],
	'CPAN'		=> 0,
	'UPSTREAM'	=> 'blead',
	},

    'Pod::Simple' =>
	{
	'MAINTAINER'	=> 'arandal',
	'DISTRIBUTION'	=> 'ARANDAL/Pod-Simple-3.07.tar.gz',
	'FILES'		=> q[lib/Pod/Simple.pm lib/Pod/Simple.pod lib/Pod/Simple],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'podlators' =>
	{
	'MAINTAINER'	=> 'rra',
	'DISTRIBUTION'	=> 'RRA/podlators-2.2.2.tar.gz',
	'FILES'		=> q[lib/Pod/{Man,ParseLink,Text,Text/{Color,Overstrike,Termcap}}.pm pod/pod2man.PL pod/pod2text.PL lib/Pod/t/{basic.*,{color,filehandle,man*,parselink,pod-parser,pod-spelling,pod,termcap,text*}.t}],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Safe' =>
	{
	'MAINTAINER'	=> 'rgarcia',
	'DISTRIBUTION'	=> 'RGARCIA/Safe-2.16.tar.gz',
	'FILES'		=> q[ext/Safe],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'Scalar-List-Utils' =>
	{
	'MAINTAINER'	=> 'gbarr',
	'DISTRIBUTION'	=> 'GBARR/Scalar-List-Utils-1.21.tar.gz',
	'FILES'		=> q[ext/List-Util],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'SelfLoader' =>
	{
	'MAINTAINER'	=> 'smueller',
	'DISTRIBUTION'	=> 'SMUELLER/SelfLoader-1.17.tar.gz',
	'FILES'		=> q[lib/SelfLoader.pm lib/SelfLoader],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'Shell' =>
	{
	'MAINTAINER'	=> 'ferreira',
	'DISTRIBUTION'	=> 'FERREIRA/Shell-0.72.tar.gz',
	'FILES'		=> q[lib/Shell.pm lib/Shell.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Storable' =>
	{
	'MAINTAINER'	=> 'ams',
	'DISTRIBUTION'	=> 'AMS/Storable-2.20.tar.gz',
	'FILES'		=> q[ext/Storable],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Switch' =>
	{
	'MAINTAINER'	=> 'rgarcia',
	'DISTRIBUTION'	=> 'RGARCIA/Switch-2.14.tar.gz',
	'FILES'		=> q[lib/Switch.pm lib/Switch],
	'CPAN'		=> 1,
	'UPSTREAM'	=> "blead",
	},

    'Sys::Syslog' =>
	{
	'MAINTAINER'	=> 'saper',
	'DISTRIBUTION'	=> 'SAPER/Sys-Syslog-0.27.tar.gz',
	'FILES'		=> q[ext/Sys-Syslog],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Text-Tabs+Wrap' =>
	{
	'MAINTAINER'	=> 'muir',
	'DISTRIBUTION'	=> 'MUIR/modules/Text-Tabs+Wrap-2009.0305.tar.gz',
	'FILES'		=>
		q[lib/Text/{Tabs,Wrap}.pm lib/Text/TabsWrap],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Term::ANSIColor' =>
	{
	'MAINTAINER'	=> 'rra',
	'DISTRIBUTION'	=> 'RRA/ANSIColor-2.00.tar.gz',
	'FILES'		=> q[lib/Term/ANSIColor.pm lib/Term/ANSIColor],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Term::Cap' =>
	{
	'MAINTAINER'	=> 'jstowe',
	'DISTRIBUTION'	=> 'JSTOWE/Term-Cap-1.12.tar.gz',
	'FILES'		=> q[lib/Term/Cap.{pm,t}],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Term::UI' =>
	{
	'MAINTAINER'	=> 'kane',
	'DISTRIBUTION'	=> 'KANE/Term-UI-0.20.tar.gz',
	'FILES'		=> q[lib/Term/UI.pm lib/Term/UI],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Test' =>
	{
	'MAINTAINER'	=> 'sburke',
	'DISTRIBUTION'	=> 'SBURKE/Test-1.25.tar.gz',
	'FILES'		=> q[lib/Test.pm lib/Test/t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Test::Harness' =>
	{
	'MAINTAINER'	=> 'andya',
	'DISTRIBUTION'	=> 'ANDYA/Test-Harness-3.17.tar.gz',
	'FILES'		=> q[ext/Test-Harness],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Test::Simple' =>
	{
	'MAINTAINER'	=> 'mschwern',
	'DISTRIBUTION'	=> 'MSCHWERN/Test-Simple-0.88.tar.gz',
	'FILES'		=> q[lib/Test/Simple.pm lib/Test/Simple
			     lib/Test/Builder.pm lib/Test/Builder
			     lib/Test/More.pm lib/Test/Tutorial.pod
			     t/lib/Test/Simple t/lib/Dev/Null.pm],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Text::Balanced' =>
	{
	'MAINTAINER'	=> 'dmanura',
	'DISTRIBUTION'	=> 'DCONWAY/Text-Balanced-v2.0.0.tar.gz',
	'FILES'		=> q[lib/Text/Balanced.pm lib/Text/Balanced],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Text::ParseWords' =>
	{
	'MAINTAINER'	=> 'chorny',
	'DISTRIBUTION'	=> 'CHORNY/Text-ParseWords-3.27.zip',
	'FILES'		=> q[lib/Text/ParseWords{.pm,.t,}],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Text::Soundex' =>
	{
	'MAINTAINER'	=> 'markm',
	'DISTRIBUTION'	=> 'MARKM/Text-Soundex-3.03.tar.gz',
	'FILES'		=> q[ext/Text-Soundex],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Thread::Queue' =>
	{
	'MAINTAINER'	=> 'jdhedden',
	'DISTRIBUTION'	=> 'JDHEDDEN/Thread-Queue-2.11.tar.gz',
	'FILES'		=> q[lib/Thread/Queue.pm lib/Thread/Queue],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'Thread::Semaphore' =>
	{
	'MAINTAINER'	=> 'jdhedden',
	'DISTRIBUTION'	=> 'JDHEDDEN/Thread-Semaphore-2.09.tar.gz',
	'FILES'		=> q[lib/Thread/Semaphore.pm lib/Thread/Semaphore],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'threads' =>
	{
	'MAINTAINER'	=> 'jdhedden',
	'DISTRIBUTION'	=> 'JDHEDDEN/threads-1.72.tar.gz',
	'FILES'		=> q[ext/threads],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'threads::shared' =>
	{
	'MAINTAINER'	=> 'jdhedden',
	'DISTRIBUTION'	=> 'JDHEDDEN/threads-shared-1.28.tar.gz',
	'FILES'		=> q[ext/threads-shared],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'blead',
	},

    'Tie::File' =>
	{
	'MAINTAINER'	=> 'mjd',
	'DISTRIBUTION'	=> 'MJD/Tie-File-0.96.tar.gz',
	'FILES'		=> q[lib/Tie/File.pm lib/Tie/File],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Tie::RefHash' =>
	{
	'MAINTAINER'	=> 'nuffin',
	'DISTRIBUTION'	=> 'NUFFIN/Tie-RefHash-1.38.tar.gz',
	'FILES'		=> q[lib/Tie/RefHash.pm lib/Tie/RefHash],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'cpan',
	},

    'Time::HiRes' =>
	{
	'MAINTAINER'	=> 'zefram',
	'DISTRIBUTION'	=> 'JHI/Time-HiRes-1.9719.tar.gz',
	'FILES'		=> q[ext/Time-HiRes],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Time::Local' =>
	{
	'MAINTAINER'	=> 'drolsky',
	'DISTRIBUTION'	=> 'DROLSKY/Time-Local-1.1901.tar.gz',
	'FILES'		=> q[lib/Time/Local.{pm,t}],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Time::Piece' =>
	{
	'MAINTAINER'	=> 'msergeant',
	'DISTRIBUTION'	=> 'MSERGEANT/Time-Piece-1.14.tar.gz',
	'FILES'		=> q[ext/Time-Piece],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Unicode::Collate' =>
	{
	'MAINTAINER'	=> 'sadahiro',
	'DISTRIBUTION'	=> 'SADAHIRO/Unicode-Collate-0.52.tar.gz',
	'FILES'		=> q[lib/Unicode/Collate.pm
			     lib/Unicode/Collate],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'first-come',
	},

    'Unicode::Normalize' =>
	{
	'MAINTAINER'	=> 'sadahiro',
	'DISTRIBUTION'	=> 'SADAHIRO/Unicode-Normalize-1.02.tar.gz',
	'FILES'		=> q[ext/Unicode-Normalize],
	'CPAN'		=> 1,
	'UPSTREAM'	=> 'first-come',
	},

    'version' =>
	{
	'MAINTAINER'	=> 'jpeacock',
	'DISTRIBUTION'	=> 'JPEACOCK/version-0.76.tar.gz',
	'FILES'		=> q[lib/version.pm lib/version.pod lib/version.t],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'vms' =>
	{
	'MAINTAINER'	=> 'craig',
	'FILES'		=> q[vms configure.com README.vms],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'warnings' =>
	{
	'MAINTAINER'	=> 'pmqs',
	'FILES'		=> q[warnings.pl lib/warnings.{pm,t}
			     lib/warnings t/lib/warnings],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'win32' =>
	{
	'MAINTAINER'	=> 'jand',
	'FILES'		=> q[win32 t/win32 README.win32 ext/Win32CORE],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},

    'Win32' =>
	{
	'MAINTAINER'	=> 'jand',
	'DISTRIBUTION'	=> "JDB/Win32-0.39.tar.gz",
	'FILES'		=> q[ext/Win32],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'Win32API::File' =>
	{
	'MAINTAINER'	=> 'tyemq',
	'DISTRIBUTION'	=> 'CHORNY/Win32API-File-0.1101.zip',
	'FILES'		=> q[ext/Win32API-File],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    'XSLoader' =>
	{
	'MAINTAINER'	=> 'saper',
	'DISTRIBUTION'	=> 'SAPER/XSLoader-0.10.tar.gz',
	'FILES'		=> q[ext/DynaLoader/t/XSLoader.t ext/DynaLoader/XSLoader_pm.PL],
	'CPAN'		=> 1,
	'UPSTREAM'	=> undef,
	},

    's2p' =>
	{
	'MAINTAINER'	=> 'laun',
	'FILES'		=> q[x2p/s2p.PL],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},


    # this pseudo-module represents all the files under ext/ and lib/
    # that aren't otherwise claimed. This means that the following two
    # commands will check that every file under ext/ and lib/ is
    # accounted for, and that there are no duplicates:
    #
    #    perl Porting/Maintainers --checkmani lib ext
    #    perl Porting/Maintainers --checkmani 

    '_PERLLIB' =>
	{
	'MAINTAINER'	=> 'p5p',
	'FILES'		=> q[
				ext/B/B.pm
				ext/B/typemap
				ext/B/Makefile.PL
				ext/B/defsubs_h.PL
				ext/B/O.pm
				ext/B/B.xs
				ext/B/B/Terse.pm
				ext/B/B/Showlex.pm
				ext/B/B/Xref.pm
				ext/B/t/f_map
				ext/B/t/showlex.t
				ext/B/t/o.t
				ext/B/t/optree_varinit.t
				ext/B/t/concise-xs.t
				ext/B/t/optree_check.t
				ext/B/t/OptreeCheck.pm
				ext/B/t/optree_specials.t
				ext/B/t/f_sort.t
				ext/B/t/pragma.t
				ext/B/t/f_sort
				ext/B/t/b.t
				ext/B/t/optree_samples.t
				ext/B/t/optree_concise.t
				ext/B/t/optree_constants.t
				ext/B/t/optree_sort.t
				ext/B/t/terse.t
				ext/B/t/xref.t
				ext/B/t/f_map.t
				ext/B/t/optree_misc.t
				ext/B/hints/openbsd.pl
				ext/B/hints/darwin.pl

				ext/Devel-DProf/
				ext/Devel-Peek/
				ext/DynaLoader/
				    !ext/DynaLoader/t/XSLoader.t
				    !ext/DynaLoader/XSLoader_pm.PL
				ext/Fcntl/
				ext/File-Glob/
				ext/GDBM_File/
				ext/Hash-Util-FieldHash/
				ext/Hash-Util/
				ext/I18N-Langinfo/
				ext/NDBM_File/
				ext/ODBM_File/
				ext/Opcode/
				ext/POSIX/
				ext/PerlIO-encoding/
				ext/PerlIO-scalar/
				ext/PerlIO-via/
				ext/SDBM_File/
				ext/Socket/
				ext/Sys-Hostname/
				ext/XS-APItest/
				ext/XS-Typemap/
				ext/attrs/
				ext/attributes/
				ext/mro/
				ext/re/
				lib/AnyDBM_File.{pm,t}
				lib/Benchmark.{pm,t}
				lib/CORE.pod
				lib/Carp.{pm,t}
				lib/Carp/Heavy.pm
				lib/Class/Struct.{pm,t}
				lib/Config.t
				lib/Config/Extensions.{pm,t}
				lib/DB.{pm,t}
				lib/DBM_Filter.pm
				lib/DBM_Filter/
				lib/Devel/SelfStubber.{pm,t}
				lib/DirHandle.{pm,t}
				lib/Dumpvalue.{pm,t}
				lib/English.{pm,t}
				lib/Env.pm
				lib/Env/t/
				lib/ExtUtils/Embed.pm
				lib/ExtUtils/XSSymSet.pm
				lib/ExtUtils/t/Embed.t
				lib/ExtUtils/t/basic_finish.pl
				lib/ExtUtils/typemap
				lib/ExtUtils/xsubpp
				lib/File/Basename.{pm,t}
				lib/File/CheckTree.{pm,t}
				lib/File/Compare.{pm,t}
				lib/File/Copy.{pm,t}
				lib/File/DosGlob.{pm,t}
				lib/File/Find.pm
				lib/File/Find/
				lib/File/stat.{pm,t}
				lib/FileCache.pm
				lib/FileCache/
				lib/FileHandle.{pm,t}
				lib/FindBin.{pm,t}
				lib/Getopt/Std.{pm,t}
				lib/I18N/Collate.{pm,t}
				lib/IPC/Open2.{pm,t}
				lib/IPC/Open3.{pm,t}
				lib/Internals.t
				lib/Net/hostent.{pm,t}
				lib/Net/netent.{pm,t}
				lib/Net/protoent.{pm,t}
				lib/Net/servent.{pm,t}
				lib/PerlIO.pm
				lib/Pod/Functions.pm
				lib/Pod/Html.pm
				lib/Pod/t/Functions.t
				lib/Pod/t/InputObjects.t
				lib/Pod/t/Select.t
				lib/Pod/t/Usage.t
				lib/Pod/t/eol.t
				lib/Pod/t/html*
				lib/Pod/t/pod2html-lib.pl
				lib/Pod/t/utils.t
				lib/Search/Dict.{pm,t}
				lib/SelectSaver.{pm,t}
				lib/Symbol.{pm,t}
				lib/Term/Complete.{pm,t}
				lib/Term/ReadLine.{pm,t}
				lib/Text/Abbrev.{pm,t}
				lib/Thread.{pm,t}
				lib/Tie/Array.pm
				lib/Tie/Array/
				lib/Tie/Handle.pm
				lib/Tie/Handle/
				lib/Tie/Hash.pm
				lib/Tie/Hash/NamedCapture.pm
				lib/Tie/Memoize.{pm,t}
				lib/Tie/Scalar.{pm,t}
				lib/Tie/StdHandle.pm
				lib/Tie/SubstrHash.{pm,t}
				lib/Time/gmtime.{pm,t}
				lib/Time/localtime.{pm,t}
				lib/Time/tm.pm
				lib/UNIVERSAL.pm
				lib/Unicode/README
				lib/Unicode/UCD.{pm,t}
				lib/User/grent.{pm,t}
				lib/User/pwent.{pm,t}
				lib/abbrev.pl
				lib/assert.pl
				lib/attributes.pm
				lib/autouse.{pm,t}
				lib/bigfloat{.pl,pl.t}
				lib/bigint{.pl,pl.t}
				lib/bigrat.pl
				lib/blib.{pm,t}
				lib/bytes.{pm,t}
				lib/bytes_heavy.pl
				lib/cacheout.pl
				lib/charnames.{pm,t}
				lib/complete.pl
				lib/ctime.pl
				lib/dbm_filter_util.pl
				lib/deprecate.pm
				lib/diagnostics.{pm,t}
				lib/dotsh.pl
				lib/dumpvar.{pl,t}
				lib/exceptions.pl
				lib/fastcwd.pl
				lib/feature.{pm,t}
				lib/filetest.{pm,t}
				lib/find.pl
				lib/finddepth.pl
				lib/flush.pl
				lib/getcwd.pl
				lib/getopt.pl
				lib/getopts.pl
				lib/h2ph.t
				lib/h2xs.t
				lib/hostname.pl
				lib/importenv.pl
				lib/integer.{pm,t}
				lib/less.{pm,t}
				lib/locale.{pm,t}
				lib/look.pl
				lib/newgetopt.pl
				lib/open.{pm,t}
				lib/open2.pl
				lib/open3.pl
				lib/overload{.pm,.t,64.t}
				lib/overload/numbers.pm
				lib/overloading.{pm,t}
				lib/perl5db.{pl,t}
				lib/perl5db/
				lib/pwd.pl
				lib/shellwords.pl
				lib/sigtrap.{pm,t}
				lib/sort.{pm,t}
				lib/stat.pl
				lib/strict.{pm,t}
				lib/subs.{pm,t}
				lib/syslog.pl
				lib/tainted.pl
				lib/termcap.pl
				lib/timelocal.pl
				lib/unicore/
				lib/utf8.{pm,t}
				lib/utf8_heavy.pl
				lib/validate.pl
				lib/vars{.pm,.t,_carp.t}
				lib/vmsish.{pm,t}
			    ],
	'CPAN'		=> 0,
	'UPSTREAM'	=> undef,
	},
);

1;
