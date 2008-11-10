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
	'ams'		=> 'Abhijit Menon-Sen <ams@cpan.org>',
	'andk'		=> 'Andreas J. Koenig <andk@cpan.org>',
	'andya'		=> 'Andy Armstrong <andy@hexten.net>',
	'arandal'       => 'Allison Randal <allison@perl.org>',
	'audreyt'	=> 'Audrey Tang <cpan@audreyt.org>',
	'avar'		=> 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
	'chorny'	=> "Alexandr Ciornii <alexchorny\100gmail.com>",
	'corion'	=> 'Max Maischein <corion@corion.net>',
	'craig'		=> 'Craig Berry <craigberry@mac.com>',
	'dankogai'	=> 'Dan Kogai <dankogai@cpan.org>',
	'dconway'	=> 'Damian Conway <dconway@cpan.org>',
	'dland'		=> 'David Landgren <dland@cpan.org>',
	'dmanura'	=> 'David Manura <dmanura@cpan.org>',
	'drolsky'	=> 'Dave Rolsky <drolsky@cpan.org>',
	'elizabeth'	=> 'Elizabeth Mattijsen <liz@dijkmat.nl>',
	'ferreira'	=> 'Adriano Ferreira <ferreira@cpan.org>',
	'gbarr'		=> 'Graham Barr <gbarr@cpan.org>',
	'gaas'		=> 'Gisle Aas <gaas@cpan.org>',
	'gsar'		=> 'Gurusamy Sarathy <gsar@activestate.com>',
	'ilyam'		=> 'Ilya Martynov <ilyam@cpan.org>',
	'ilyaz'		=> 'Ilya Zakharevich <ilyaz@cpan.org>',
	'jand'		=> 'Jan Dubois <jand@activestate.com>',
	'jdhedden'	=> 'Jerry D. Hedden <jdhedden@cpan.org>',
	'jhi'		=> 'Jarkko Hietaniemi <jhi@cpan.org>',
	'jjore'		=> 'Joshua ben Jore <jjore@cpan.org>',
	'jpeacock'	=> 'John Peacock <jpeacock@rowman.com>',
	'jstowe'	=> 'Jonathan Stowe <jstowe@cpan.org>',
	'jv'		=> 'Johan Vromans <jv@cpan.org>',
	'kane'		=> 'Jos Boumans <kane@cpan.org>',
	'kwilliams'	=> 'Ken Williams <kwilliams@cpan.org>',
	'laun'		=> 'Wolfgang Laun <Wolfgang.Laun@alcatel.at>',
	'lstein'	=> 'Lincoln D. Stein <lds@cpan.org>',
	'lwall'		=> 'Larry Wall <lwall@cpan.org>',
	'marekr'	=> 'Marek Rouchal <marekr@cpan.org>',
	'markm'		=> 'Mark Mielke <markm@cpan.org>',
	'mhx'		=> 'Marcus Holland-Moritz <mhx@cpan.org>',
	'mjd'		=> 'Mark-Jason Dominus <mjd@plover.com>',
	'msergeant'	=> 'Matt Sergeant <msergeant@cpan.org>',
	'mshelor'	=> 'Mark Shelor <mshelor@cpan.org>',
	'muir'		=> 'David Muir Sharnoff <muir@cpan.org>',
	'neilb'		=> 'Neil Bowers <neilb@cpan.org>',
	'nuffin'	=> 'Yuval Kogman <nothingmuch@woobling.org>',
	'nwclark'	=> 'Nicholas Clark <nwclark@cpan.org>',
	'osfameron'	=> 'Hakim Cassimally <osfameron@perl.org>',
	'p5p'		=> 'perl5-porters <perl5-porters@perl.org>',
	'perlfaq'	=> 'perlfaq-workers <perlfaq-workers@perl.org>',
	'petdance'	=> 'Andy Lester <andy@petdance.com>',
	'pmqs'		=> 'Paul Marquess <pmqs@cpan.org>',
	'pvhp'		=> 'Peter Prymmer <pvhp@best.com>',
	'rclamp'	=> 'Richard Clamp <rclamp@cpan.org>',
	'rgarcia'	=> 'Rafael Garcia-Suarez <rgarcia@cpan.org>',
	'rkobes'	=> 'Randy Kobes <rkobes@cpan.org>',
	'rmbarker'	=> 'Robin Barker <rmbarker@cpan.org>',
	'rra'		=> 'Russ Allbery <rra@cpan.org>',
	'rurban'	=> 'Reini Urban <rurban@cpan.org>',
	'sadahiro'	=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
	'salva'		=> 'Salvador Fandiño García <salva@cpan.org>',
	'saper'		=> 'Sébastien Aperghis-Tramoni <saper@cpan.org>',
	'sburke'	=> 'Sean Burke <sburke@cpan.org>',
	'mschwern'	=> 'Michael Schwern <mschwern@cpan.org>',
	'smccam'	=> 'Stephen McCamant <smccam@cpan.org>',
	'smpeters'	=> 'Steve Peters <steve@fisharerojo.org>',
	'smueller'	=> 'Steffen Mueller <smueller@cpan.org>',
	'tels'		=> 'Tels <nospam-abuse@bloodgate.com>',
	'tomhughes'	=> 'Tom Hughes <tomhughes@cpan.org>',
	'tjenness'	=> 'Tim Jenness <tjenness@cpan.org>',
	'tyemq'		=> 'Tye McQueen <tyemq@cpan.org>',
	'yves'		=> 'Yves Orton <yves@cpan.org>',
	'zefram'	=> 'Andrew Main <zefram@cpan.org>',
	);

# The FILES is either filenames, or glob patterns, or directory
# names to be recursed down.  The CPAN can be either 1 (get the
# latest one from CPAN) or 0 (there is no valid CPAN release).

# UPSTREAM indicates where patches should go. undef implies
# that this hasn't been discussed for the module at hand.
# "blead" indicates that the copy of the module in the blead
# sources is to be considered canonical, "cpan" means that the
# module on CPAN is to be patched first. "first-come" means
# that blead can be patched freely if it is in sync with the
# latest release on CPAN.

%Modules = (

	'Archive::Extract' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Archive/Extract.pm lib/Archive/Extract],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Archive::Tar' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Archive/Tar.pm lib/Archive/Tar],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'AutoLoader' =>
		{
		'MAINTAINER'	=> 'smueller',
		'FILES'		=> q[lib/AutoLoader.pm lib/AutoSplit.pm lib/AutoLoader],
		'CPAN'		=> 1,
		'UPSTREAM'	=> "cpan",
		},

	'Attribute::Handlers' =>
		{
		'MAINTAINER'	=> 'rgarcia',
		'FILES'		=> q[lib/Attribute/Handlers.pm
				     lib/Attribute/Handlers],
		'CPAN'		=> 1,
                'UPSTREAM'      => "blead",
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
		'FILES'		=> q[ext/B/B/Lint.pm ext/B/t/lint.t
				     ext/B/t/pluglib/B/Lint/Plugin/Test.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'base' =>
		{
		'MAINTAINER'	=> 'rgarcia',
		'FILES'		=> q[lib/base.pm lib/fields.pm lib/base],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'bignum' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/big{int,num,rat}.pm lib/bignum],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Compress::Raw::Zlib' =>
		{
		'MAINTAINER'	=> 'pmqs',
		'FILES'		=> q[ext/Compress/Raw],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'constant' =>
		{
		'MAINTAINER'	=> 'saper',
		'FILES'		=> q[lib/constant.{pm,t}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Compress::Zlib' =>
		{
		'MAINTAINER'	=> 'pmqs',
		'FILES'		=> q[ext/Compress/Zlib],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'CGI' =>
		{
		'MAINTAINER'	=> 'lstein',
		'FILES'		=> q[lib/CGI.pm lib/CGI],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Class::ISA' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/Class/ISA.pm lib/Class/ISA],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'CPAN' =>
		{
		'MAINTAINER'	=> 'andk',
		'FILES'		=> q[lib/CPAN.pm lib/CPAN],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'CPANPLUS' =>
		{
		'MAINTAINER'	=> 'kane',
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
				     lib/CPANPLUS/t
				    ],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'CPANPLUS::Dist' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/CPANPLUS/Dist.pm lib/CPANPLUS/Dist/Base.pm
				     lib/CPANPLUS/Dist/MM.pm lib/CPANPLUS/Dist/Sample.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'CPANPLUS::Dist::Build' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/CPANPLUS/Dist/Build.pm lib/CPANPLUS/Dist/Build],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Cwd' =>
		{
		'MAINTAINER'	=> 'kwilliams',
		'FILES'		=> q[ext/Cwd lib/Cwd.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Data::Dumper' =>
		{
		'MAINTAINER'	=> 'ilyam', # Not gsar.
		'FILES'		=> q[ext/Data/Dumper],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'DB::File' =>
		{
		'MAINTAINER'	=> 'pmqs',
		'FILES'		=> q[ext/DB_File],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Devel::PPPort' =>
		{
		'MAINTAINER'	=> 'mhx',
		'FILES'		=> q[ext/Devel/PPPort],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Digest' =>
		{
		'MAINTAINER'	=> 'gaas',
		'FILES'		=> q[lib/Digest.pm lib/Digest],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Digest::MD5' =>
		{
		'MAINTAINER'	=> 'gaas',
		'FILES'		=> q[ext/Digest/MD5],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

        'Digest::SHA' =>
                {
                'MAINTAINER'    => 'mshelor',
                'FILES'         => q[ext/Digest/SHA],
                'CPAN'          => 1,
                'UPSTREAM'	=> undef,
                },

	'Encode' =>
		{
		'MAINTAINER'	=> 'dankogai',
		'FILES'		=> q[ext/Encode],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'encoding::warnings' =>
		{
		'MAINTAINER'	=> 'audreyt',
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
		'FILES'		=> q[lib/Exporter.pm lib/Exporter.t lib/Exporter/Heavy.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'ExtUtils::CBuilder' =>
		{
		'MAINTAINER'	=> 'kwilliams',
		'FILES'		=> q[lib/ExtUtils/CBuilder.pm lib/ExtUtils/CBuilder],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'ExtUtils::Command' =>
		{
		'MAINTAINER'	=> 'rkobes',
		'FILES'		=> q[lib/ExtUtils/Command.pm
				     lib/ExtUtils/t/{cp,eu_command}.t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'ExtUtils::Constant' =>
		{
		'MAINTAINER'	=> 'nwclark',
		'FILES'		=> q[lib/ExtUtils/Constant.pm lib/ExtUtils/Constant
				     lib/ExtUtils/t/Constant.t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

        'ExtUtils::Install' =>
		{
		'MAINTAINER' => 'yves',
		# MakeMaker has a basic.t too, and we use that.
		'FILES' => q[lib/ExtUtils/{Install,Installed,Packlist}.pm
			     lib/ExtUtils/t/{Install,Installapi2,Packlist,can_write_dir}.t],
		'CPAN' => 1,
		'UPSTREAM' => undef,
		},

	'ExtUtils::MakeMaker' =>
		{
		'MAINTAINER'	=> 'mschwern',
		'FILES'	=> q[lib/ExtUtils/{Liblist,MakeMaker,Mkbootstrap,Mksymlists,MM*,MY,testlib}.pm
			lib/ExtUtils/{Command,Liblist,MakeMaker}
			lib/ExtUtils/t/{[0-9FLV-Zabdf-z]*,IN*,Mkbootstrap,MM_*,PL_FILES,cd,config}.t
			t/lib/MakeMaker t/lib/TieIn.pm t/lib/TieOut.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'ExtUtils::Manifest' =>
		{
		'MAINTAINER'	=> 'rkobes',
		'FILES'		=> q[lib/ExtUtils/{Manifest.pm,MANIFEST.SKIP} lib/ExtUtils/t/Manifest.t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'ExtUtils::ParseXS' =>
		{
		'MAINTAINER'	=> 'kwilliams',
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
		'FILES'		=> q[lib/File/Fetch.pm lib/File/Fetch],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'File::Path' =>
		{
		'MAINTAINER'	=> 'dland',
		'FILES'		=> q[lib/File/Path.pm lib/File/Path.t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'File::Spec' =>
		{
		'MAINTAINER'	=> 'kwilliams',
		'FILES'		=> q[lib/File/Spec.pm lib/File/Spec],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'File::Temp' =>
		{
		'MAINTAINER'	=> 'tjenness',
		'FILES'		=> q[lib/File/Temp.pm lib/File/Temp],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Filter::Simple' =>
		{
		'MAINTAINER'	=> 'smueller',
		'FILES'		=> q[lib/Filter/Simple.pm lib/Filter/Simple],
		'CPAN'		=> 1,
                'UPSTREAM'      => "blead",
		},

	'Filter::Util::Call' =>
		{
		'MAINTAINER'	=> 'pmqs',
		'FILES'		=> q[ext/Filter/Util/Call ext/Filter/t/call.t
				     t/lib/filter-util.pl],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Getopt::Long' =>
		{
		'MAINTAINER'	=> 'jv',
		'FILES'		=> q[lib/Getopt/Long.pm lib/Getopt/Long],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'I18N::LangTags' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/I18N/LangTags.pm lib/I18N/LangTags],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'if' =>
		{
		'MAINTAINER'	=> 'ilyaz',
		'FILES'		=> q[lib/if.{pm,t}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'IO' =>
		{
		'MAINTAINER'	=> 'gbarr',
		'FILES'		=> q[ext/IO],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'IO::Compress::Base' =>
		{
		'MAINTAINER'	=> 'pmqs',
		'FILES'		=> q[ext/IO_Compress_Base],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'IO::Compress::Zlib' =>
		{
		'MAINTAINER'	=> 'pmqs',
		'FILES'		=> q[ext/IO_Compress_Zlib],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'IO::Zlib' =>
		{
		'MAINTAINER'	=> 'tomhughes',
		'FILES'		=> q[lib/IO/Zlib.pm lib/IO/Zlib],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'IPC::Cmd' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/IPC/Cmd lib/IPC/Cmd.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'lib' =>
		{
		'MAINTAINER'	=> 'smueller',
		'FILES'		=>
			q[lib/lib_pm.PL lib/lib.t],
		'CPAN'		=> 1,
                'UPSTREAM'      => "blead",
		},

	'libnet' =>
		{
		'MAINTAINER'	=> 'gbarr',
		'FILES'		=>
			q[lib/Net/{Cmd,Config,Domain,FTP,Netrc,NNTP,POP3,SMTP,Time}.pm lib/Net/ChangeLog lib/Net/FTP lib/Net/*.eg lib/Net/libnetFAQ.pod lib/Net/README lib/Net/t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Scalar-List-Utils' =>
		{
		'MAINTAINER'	=> 'gbarr',
		'FILES'		=> q[ext/List/Util],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Locale::Codes' =>
		{
		'MAINTAINER'	=> 'neilb',
		'FILES'		=> q[lib/Locale/{Codes,Constants,Country,Currency,Language,Script}*],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Locale::Maketext' =>
		{
		'MAINTAINER'	=> 'ferreira',
		'FILES'		=> q[lib/Locale/Maketext.pm lib/Locale/Maketext.pod lib/Locale/Maketext/ChangeLog lib/Locale/Maketext/{Guts,GutsLoader}.pm lib/Locale/Maketext/README lib/Locale/Maketext/TPJ13.pod lib/Locale/Maketext/t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Locale::Maketext::Simple' =>
		{
		'MAINTAINER'	=> 'audreyt',
		'FILES'		=> q[lib/Locale/Maketext/Simple.pm lib/Locale/Maketext/Simple],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Log::Message' =>
		{
		'MAINTAINER'    => 'kane',
                'FILES'         => q[lib/Log/Message.pm lib/Log/Message/{Config,Handlers,Item}.pm lib/Log/Message/t],
                'CPAN'          => 1,
		'UPSTREAM'      => undef,
		},

	'Log::Message::Simple' =>
                {
                'MAINTAINER'    => 'kane',
                'FILES'         => q[lib/Log/Message/Simple.pm lib/Log/Message/Simple],
                'CPAN'          => 1,
                'UPSTREAM'      => undef,
                },

	'mad' =>
		{
		'MAINTAINER'	=> 'lwall',
		'FILES'		=> q[mad],
		'CPAN'		=> 0,
		'UPSTREAM'	=> undef,
		},

	'Math::BigFloat' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/Math/BigFloat.pm lib/Math/BigFloat],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Math::BigInt' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/Math/BigInt.pm lib/Math/BigInt
				     t/lib/Math],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Math::BigInt::FastCalc' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[ext/Math/BigInt/FastCalc],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Math::BigRat' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/Math/BigRat.pm lib/Math/BigRat],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

        'Math::Complex' =>
                {
                'MAINTAINER'    => 'zefram',
                'FILES'         => q[lib/Math/Complex.pm lib/Math/Trig.pm],
                'CPAN'          => 1,
                'UPSTREAM'      => undef,
                },

	'Memoize' =>
		{
		'MAINTAINER'	=> 'mjd',
		'FILES'		=> q[lib/Memoize.pm lib/Memoize],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'MIME::Base64' =>
		{
		'MAINTAINER'	=> 'gaas',
		'FILES'		=> q[ext/MIME/Base64],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Module::Build' =>
		{
		'MAINTAINER'	=> 'kwilliams',
		'FILES'		=> q[lib/Module/Build lib/Module/Build.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Module::CoreList' =>
		{
		'MAINTAINER'	=> 'rgarcia',
		'FILES'		=> q[lib/Module/CoreList lib/Module/CoreList.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Module::Load' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Module/Load/t lib/Module/Load.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Module::Load::Conditional' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Module/Load/Conditional
				     lib/Module/Load/Conditional.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Module::Loaded' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Module/Loaded lib/Module/Loaded.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	# NB. tests are located in t/Module_Pluggable to avoid directory
	# depth issues on VMS
	'Module::Pluggable' =>
		{
		'MAINTAINER'	=> 'simonw',
		'FILES'		=> q[ext/Module/Pluggable t/Module_Pluggable],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Net::Ping' =>
		{
		'MAINTAINER'	=> 'smpeters',
		'FILES'		=> q[lib/Net/Ping.pm lib/Net/Ping],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'NEXT' =>
		{
		'MAINTAINER'	=> 'dconway',
		'FILES'		=> q[lib/NEXT.pm lib/NEXT],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Object::Accessor' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Object/Accessor.pm lib/Object/Accessor],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Package::Constants' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Package/Constants lib/Package/Constants.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Params::Check' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Params/Check lib/Params/Check.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'parent' =>
		{
		'MAINTAINER'	=> 'corion',
		'FILES'		=> q[lib/parent lib/parent.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
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
		'FILES'		=> q[lib/PerlIO/via/QuotedPrint.pm
				     lib/PerlIO/via/t/QuotedPrint.t],
		'CPAN'		=> 1,
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

	'perlthrtut' =>
		{
		'MAINTAINER'	=> 'elizabeth',
		'FILES'		=> q[pod/perlthrtut.pod],
		'CPAN'		=> 0,
		'UPSTREAM'	=> undef,
		},

	'Pod::Escapes' =>
                {
                'MAINTAINER'    => 'sburke',
                'FILES'         => q[lib/Pod/Escapes.pm lib/Pod/Escapes],
                'CPAN'          => 1,
                'UPSTREAM'      => undef,
                },

        'Pod::Parser' => {
		'MAINTAINER'	=> 'marekr',
		'FILES' => q[lib/Pod/{InputObjects,Parser,ParseUtils,Select,PlainText,Usage,Checker,Find}.pm pod/pod{select,2usage,checker}.PL t/pod/testcmp.pl t/pod/testp2pt.pl t/pod/testpchk.pl t/pod/emptycmd.* t/pod/find.t t/pod/for.* t/pod/headings.* t/pod/include.* t/pod/included.* t/pod/lref.* t/pod/multiline_items.* t/pod/nested_items.* t/pod/nested_seqs.* t/pod/oneline_cmds.* t/pod/poderrs.* t/pod/pod2usage.* t/pod/podselect.* t/pod/special_seqs.*],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

        'Pod::Simple' =>
                {
		'MAINTAINER'	=> 'arandal',
		'FILES'		=> q[lib/Pod/Simple.pm lib/Pod/Simple.pod lib/Pod/Simple],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Pod::LaTeX' =>
		{
		'MAINTAINER'	=> 'tjenness',
		'FILES'		=> q[lib/Pod/LaTeX.pm lib/Pod/t/pod2latex.t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'podlators' =>
		{
		'MAINTAINER'	=> 'rra',
		'FILES'		=> q[lib/Pod/{Man,ParseLink,Text,Text/{Color,Overstrike,Termcap}}.pm pod/pod2man.PL pod/pod2text.PL lib/Pod/t/{basic.*,{color,filehandle,man*,parselink,pod-parser,pod-spelling,pod,termcap,text*}.t}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Pod::Perldoc' =>
		{
		'MAINTAINER'	=> 'ferreira',
		'FILES'		=> q[lib/Pod/Perldoc.pm lib/Pod/Perldoc],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Pod::Plainer' =>
		{
		'MAINTAINER'	=> 'rmbarker',
		'FILES'		=> q[lib/Pod/Plainer.pm t/pod/plainer.t],
		'CPAN'		=> 0,
		'UPSTREAM'	=> undef,
		},

	'Safe' =>
		{
		'MAINTAINER'	=> 'rgarcia',
		'FILES'		=> q[ext/Safe ext/Opcode/Safe.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'SelfLoader' =>
		{
		'MAINTAINER'	=> 'smueller',
		'FILES'		=> q[lib/SelfLoader.pm lib/SelfLoader],
		'CPAN'		=> 1,
		'UPSTREAM'	=> "blead",
		},

	'Shell' =>
		{
		'MAINTAINER'	=> 'ferreira',
		'FILES'		=> q[lib/Shell.pm lib/Shell.t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Storable' =>
		{
		'MAINTAINER'	=> 'ams',
		'FILES'		=> q[ext/Storable],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Switch' =>
		{
		'MAINTAINER'	=> 'rgarcia',
		'FILES'		=> q[lib/Switch.pm lib/Switch],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Sys::Syslog' =>
		{
		'MAINTAINER'	=> 'saper',
		'FILES'		=> q[ext/Sys/Syslog],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'TabsWrap' =>
		{
		'MAINTAINER'	=> 'muir',
		'FILES'		=>
			q[lib/Text/{Tabs,Wrap}.pm lib/Text/TabsWrap],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Text::Balanced' =>
		{
		'MAINTAINER'	=> 'dmanura',
		'FILES'		=> q[lib/Text/Balanced.pm lib/Text/Balanced],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Text::ParseWords' =>
		{
		'MAINTAINER'	=> 'chorny',
		'FILES'		=> q[lib/Text/ParseWords{.pm,.t,}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Text::Soundex' =>
		{
		'MAINTAINER'	=> 'markm',
		'FILES'		=> q[ext/Text/Soundex],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Term::ANSIColor' =>
		{
		'MAINTAINER'	=> 'rra',
		'FILES'		=> q[lib/Term/ANSIColor.pm lib/Term/ANSIColor],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Term::UI' =>
		{
		'MAINTAINER'	=> 'kane',
		'FILES'		=> q[lib/Term/UI.pm lib/Term/UI],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Test' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/Test.pm lib/Test/t],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Test::Harness' =>
		{
		'MAINTAINER'	=> 'andya',
		'FILES'		=> q[ext/Test/Harness],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Test::Simple' =>
		{
		'MAINTAINER'	=> 'mschwern',
		'FILES'		=> q[lib/Test/Simple.pm lib/Test/Simple
				     lib/Test/Builder.pm lib/Test/Builder
				     lib/Test/More.pm lib/Test/Tutorial.pod
				     t/lib/Test/Simple t/lib/Dev/Null.pm],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Term::Cap' =>
		{
		'MAINTAINER'	=> 'jstowe',
		'FILES'		=> q[lib/Term/Cap.{pm,t}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Thread::Queue' =>
		{
		'MAINTAINER'	=> 'jdhedden',
		'FILES'		=> q[lib/Thread/Queue.pm lib/Thread/Queue],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Thread::Semaphore' =>
		{
		'MAINTAINER'	=> 'jdhedden',
		'FILES'		=> q[lib/Thread/Semaphore.pm lib/Thread/Semaphore],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'threads' =>
		{
		'MAINTAINER'	=> 'jdhedden',
		'FILES'		=> q[ext/threads/hints ext/threads/t
				     ext/threads/threads.{pm,xs}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'threads::shared' =>
		{
		'MAINTAINER'	=> 'jdhedden',
		'FILES'		=> q[ext/threads/shared],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Tie::File' =>
		{
		'MAINTAINER'	=> 'mjd',
		'FILES'		=> q[lib/Tie/File.pm lib/Tie/File],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Tie::RefHash' =>
		{
		'MAINTAINER'	=> 'nuffin',
		'FILES'		=> q[lib/Tie/RefHash.pm lib/Tie/RefHash],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Time::HiRes' =>
		{
		'MAINTAINER'	=> 'zefram',
		'FILES'		=> q[ext/Time/HiRes],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Time::Local' =>
		{
		'MAINTAINER'	=> 'drolsky',
		'FILES'		=> q[lib/Time/Local.{pm,t}],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

        'Time::Piece' =>
                {
                'MAINTAINER'    => 'msergeant',
                'FILES'         => q[ext/Time/Piece],
                'CPAN'          => 1,
                'UPSTREAM'      => undef,
                },

	'Unicode::Collate' =>
		{
		'MAINTAINER'	=> 'sadahiro',
		'FILES'		=> q[lib/Unicode/Collate.pm
				     lib/Unicode/Collate],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Unicode::Normalize' =>
		{
		'MAINTAINER'	=> 'sadahiro',
		'FILES'		=> q[ext/Unicode/Normalize],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'version' =>
		{
		'MAINTAINER'	=> 'jpeacock',
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
		'FILES'		=> q[ext/Win32],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'Win32API::File' =>
		{
		'MAINTAINER'	=> 'tyemq',
		'FILES'		=> q[ext/Win32API/File],
		'CPAN'		=> 1,
		'UPSTREAM'	=> undef,
		},

	'XSLoader' =>
		{
		'MAINTAINER'	=> 'saper',
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
	);

1;
