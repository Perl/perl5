# A simple listing of core modules that have specific maintainers.
# Most (but not all) of the modules have dual lives in the core and
# in CPAN.

%Maintainers =
	(
	'ams'		=> 'Abhijit Menon-Sen <ams@cpan.org>',
	'andreas'	=> 'Andreas J. Koenig <andk@cpan.org>',
	'arthur'	=> 'Arthur Bergman <abergman@cpan.org>',
	'autarch'	=> 'Dave Rolsky <drolsky@cpan.org>',
	'bbb'		=> 'Rob Brown <bbb@cpan.org>',
	'damian'	=> 'Damian Conway <dconway@cpan.org>',
	'dankogai'	=> 'Dan Kogai <dankogai@cpan.org>',
	'gbarr'		=> 'Graham Barr <gbarr@cpan.org>',
	'gisle'		=> 'Gisle Aas <gaas@cpan.org>',
	'ilyam'		=> 'Ilya Martynov <ilyam@cpan.org>',
	'ilyaz'		=> 'Ilya Zakharevich <ilyaz@cpan.org>',
	'jhi'		=> 'Jarkko Hietaniemi <jhi@cpan.org>',
	'jns'		=> 'Jonathan Stowe <jstowe@cpan.org>',
	'jvromans'	=> 'Johan Vromans <jv@cpan.org>',
	'kenw'		=> 'Ken Williams <kwilliams@cpan.org>',
	'lstein'	=> 'Lincoln D. Stein <lds@cpan.org>',
	'marekr'	=> 'Marek Rouchal <marekr@cpan.org>',
	'mjd'		=> 'Mark-Jason Dominus <mjd@cpan.org>',
	'muir'		=> 'David Muir Sharnoff <muir@cpan.org>',
	'neilb'		=> 'Neil Bowers <neilb@cpan.org>',
	'p5p'		=> 'perl5-porters <perl5-porters@perl.org>',
	'petdance'	=> 'Andy Lester <petdance@cpan.org>',
	'pmarquess'	=> 'Paul Marquess <pmqs@cpan.org>',
	'rmbarker'	=> 'Robin Barker <rmbarker@cpan.org>',
	'rra'		=> 'Russ Allbery <rra@cpan.org>',
	'sadahiro'	=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
	'sburke'	=> 'Sean Burke <sburke@cpan.org>',
	'schwern'	=> 'Michael Schwern <schwern@cpan.org>',
	'smcc'		=> 'Stephen McCamant <smccam@cpan.org>',
	'tels'		=> 'perl_dummy a-t bloodgate.com',
	'tjenness'	=> 'Tim Jenness <tjenness@cpan.org>'
	);

# The FILES is either filenames, or glob patterns, or directory
# names to be recursed down.  The CPAN can be either 1 (get the
# latest one from CPAN) or 0 (there is no valid CPAN release).

%Modules = (

	'Attribute::Handlers' =>
		{
		'MAINTAINER'	=> 'arthur',
		'FILES'		=> q[lib/Attribute/Handlers.pm
				     lib/Attribute/Handlers],
		'CPAN'		=> 1,
		},

	'B::Concise' =>
		{
		'MAINTAINER'	=> 'smcc',
		'FILES'		=> q[ext/B/B/Concise.pm ext/B/t/concise.t],
		'CPAN'		=> 0,
		},

	'B::Deparse' =>
		{
		'MAINTAINER'	=> 'smcc',
		'FILES'		=> q[ext/B/B/Deparse.pm ext/B/t/deparse.t],
		'CPAN'		=> 0,
		},

	'bignum' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/big{int,num,rat}.pm lib/bignum],
		'CPAN'		=> 1,
		},

	'CGI' =>
		{
		'MAINTAINER'	=> 'lstein',
		'FILES'		=> q[lib/CGI.pm lib/CGI],
		'CPAN'		=> 1,
		},

	'Class::ISA' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/Class/ISA.pm lib/Class/ISA],
		'CPAN'		=> 1,
		},

	'CPAN' =>
		{
		'MAINTAINER'	=> 'andreas',
		'FILES'		=> q[lib/CPAN.pm lib/CPAN],
		'CPAN'		=> 1,
		},

	'Data::Dumper' =>
		{
		'MAINTAINER'	=> 'ilyam', # Not gsar.
		'FILES'		=> q[ext/Data/Dumper],
		'CPAN'		=> 1,
		},

	'DB::File' =>
		{
		'MAINTAINER'	=> 'pmarquess',
		'FILES'		=> q[ext/DB_File],
		'CPAN'		=> 1,
		},

	'Devel::PPPort' =>
		{
		'MAINTAINER'	=> 'pmarquess',
		'FILES'		=> q[ext/Devel/PPPort],
		'CPAN'		=> 1,
		},

	'Digest' =>
		{
		'MAINTAINER'	=> 'gisle',
		'FILES'		=> q[lib/Digest.{pm,t}],
		'CPAN'		=> 1,
		},

	'Digest::MD5' =>
		{
		'MAINTAINER'	=> 'gisle',
		'FILES'		=> q[ext/Digest/MD5],
		'CPAN'		=> 1,
		},

	'Encode' =>
		{
		'MAINTAINER'	=> 'dankogai',
		'FILES'		=> q[ext/Encode],
		'CPAN'		=> 1,
		},

	'Errno' =>
		{
		'MAINTAINER'	=> 'p5p', # Not gbarr.
		'FILES'		=> q[ext/Data/Dumper],
		'CPAN'		=> 0,
		},

	'ExtUtils::MakeMaker' =>
		{
		'MAINTAINER'	=> 'schwern',
		'FILES'		=> q[lib/ExtUtils/{Command,Install,Installed,Liblist,MakeMaker,Manifest,Mkbootstrap,Mksymlists,MM*,MY,Packlist,testlib}.pm lib/ExtUtils/{Command,Liblist,MakeMaker}
				     lib/ExtUtils/t t/lib/MakeMaker t/lib/TieIn.pm t/lib/TieOut.pm],
		'CPAN'		=> 1,
		},

	'File::Spec' =>
		{
		'MAINTAINER'	=> 'kenw',
		'FILES'		=> q[lib/File/Spec.pm lib/File/Spec],
		'CPAN'		=> 1,
		},

	'File::Temp' =>
		{
		'MAINTAINER'	=> 'tjenness',
		'FILES'		=> q[lib/File/Temp.pm lib/File/Temp],
		'CPAN'		=> 1,
		},

	'Filter::Simple' =>
		{
		'MAINTAINER'	=> 'damian',
		'FILES'		=> q[lib/Filter/Simple.pm lib/Filter/Simple
				     t/lib/Filter/Simple],
		'CPAN'		=> 1,
		},

	'Filter::Util::Call' =>
		{
		'MAINTAINER'	=> 'pmarquess',
		'FILES'		=> q[ext/Filter/Util/Call
				     t/lib/filter-util.pl],
		'CPAN'		=> 1,
		},

	'Getopt::Long' =>
		{
		'MAINTAINER'	=> 'jvromans',
		'FILES'		=> q[lib/Getopt/Long.pm lib/Getopt/Long],
		'CPAN'		=> 1,
		},

	'I18N::LangTags' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/I18N/LangTags.pm lib/I18N/LangTags],
		'CPAN'		=> 1,
		},

	'if' =>
		{
		'MAINTAINER'	=> 'ilyaz',
		'FILES'		=> q[lib/if.{pm,t}],
		'CPAN'		=> 1,
		},

	'IO' =>
		{
		'MAINTAINER'	=> 'p5p', # Not gbarr.
		'FILES'		=> q[ext/IO],
		'CPAN'		=> 0,
		},

	'libnet' =>
		{
		'MAINTAINER'	=> 'gbarr',
		'FILES'		=>
			q[lib/Net/{Cmd,Config,Domain,FTP,Netrc,NNTP,POP3,SMTP,Time}.pm lib/Net/ChangeLog.libnet lib/Net/FTP lib/Net/*.eg lib/Net/libnetFAQ.pod lib/Net/README.libnet lib/Net/t],
		'CPAN'		=> 1,
		},

	'Scalar-List-Util' =>
		{
		'MAINTAINER'	=> 'gbarr',
		'FILES'		=> q[ext/List/Util],
		'CPAN'		=> 1,
		},

	'Locale::Codes' =>
		{
		'MAINTAINER'	=> 'neilb',
		'FILES'		=> q[lib/Locale/{Codes,Constants,Country,Currency,Language,Script}*],
		'CPAN'		=> 1,
		},

	'Locale::Maketext' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/Locale/Maketext.pm lib/Locale/Maketext],
		'CPAN'		=> 1,
		},

	'Math::BigFloat' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/Math/BigFloat.pm lib/Math/BigFloat],
		'CPAN'		=> 1,
		},

	'Math::BigInt' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/Math/BigInt.pm lib/Math/BigInt
				     t/lib/Math],
		'CPAN'		=> 1,
		},

	'Math::BigRat' =>
		{
		'MAINTAINER'	=> 'tels',
		'FILES'		=> q[lib/Math/BigRat.pm lib/Math/BigRat],
		'CPAN'		=> 1,
		},

	'Memoize' =>
		{
		'MAINTAINER'	=> 'mjd',
		'FILES'		=> q[lib/Memoize.pm lib/Memoize],
		'CPAN'		=> 1,
		},

	'MIME::Base64' =>
		{
		'MAINTAINER'	=> 'gisle',
		'FILES'		=> q[ext/MIME/Base64],
		'CPAN'		=> 1,
		},

	'Net::Ping' =>
		{
		'MAINTAINER'	=> 'bbb',
		'FILES'		=> q[lib/Net/Ping.pm lib/Net/Ping],
		'CPAN'		=> 1,
		},

	'NEXT' =>
		{
		'MAINTAINER'	=> 'damian',
		'FILES'		=> q[lib/NEXT.pm lib/NEXT],
		'CPAN'		=> 1,
		},

	'PerlIO' =>
		{
		'MAINTAINER'	=> 'p5p',
		'FILES'		=> q[ext/PerlIO lib/PerlIO],
		'CPAN'		=> 1,
		},

	'Pod::Find' =>
		{
		'MAINTAINER'	=> 'marekr',
		'FILES'		=> q[lib/Pod/Find.pm t/pod/find.t],
		'CPAN'		=> 1,
		},

	'Pod::LaTeX' =>
		{
		'MAINTAINER'	=> 'tjenness',
		'FILES'		=> q[lib/Pod/LaTeX.pm lib/Pod/t/pod2latex.t],
		'CPAN'		=> 1,
		},

	'podlators' =>
		{
		'MAINTAINER'	=> 'rra',
		'FILES'		=> q[lib/Pod/{Checker,Find,Html,InputObjects,Man,ParseLink,Parser,ParseUtils,PlainText,Select,Text,Text/{Color,Overstrike,Termcap},Usage}.pm pod/pod2man.PL pod/pod2text.PL lib/Pod/t/{basic.*,{basic,man,parselink,text*}.t}],
		'CPAN'		=> 1,
		},

	'Pod::Perldoc' =>
		{
		'MAINTAINER'	=> 'sburke',
		'FILES'		=> q[lib/Pod/Perldoc.pm],
		'CPAN'		=> 1,
		},

	'Pod::Plainer' =>
		{
		'MAINTAINER'	=> 'rmbarker',
		'FILES'		=> q[lib/Pod/Plainer.pm],
		'CPAN'		=> 1,
		},

	'Storable' =>
		{
		'MAINTAINER'	=> 'ams',
		'FILES'		=> q[ext/Storable],
		'CPAN'		=> 1,
		},

	'Switch' =>
		{
		'MAINTAINER'	=> 'damian',
		'FILES'		=> q[lib/Switch.pm lib/Switch],
		'CPAN'		=> 1,
		},

	'TabsWrap' =>
		{
		'MAINTAINER'	=> 'muir',
		'FILES'		=>
			q[lib/Text/{Tabs,Wrap}.pm lib/Text/TabsWrap],
		'CPAN'		=> 1,
		},

	'Text::Balanced' =>
		{
		'MAINTAINER'	=> 'damian',
		'FILES'		=> q[lib/Text/Balanced.pm lib/Text/Balanced],
		'CPAN'		=> 1,
		},

	'Term::ANSIColor' =>
		{
		'MAINTAINER'	=> 'rra',
		'FILES'		=> q[lib/Term/ANSIColor.pm lib/Term/ANSIColor],
		},

	'Test::Builder' =>
		{
		'MAINTAINER'	=> 'schwern',
		'FILES'		=> q[lib/Test/Builder.pm],
		},

	'Test::Harness' =>
		{
		'MAINTAINER'	=> 'petdance',
		'FILES'		=> q[lib/Test/Harness.pm lib/Test/Harness
				     t/lib/sample-tests],
		'CPAN'		=> 1,
		},

	'Test::More' =>
		{
		'MAINTAINER'	=> 'schwern',
		'FILES'		=> q[lib/Test/More.pm],
		'CPAN'		=> 1,
		},

	'Test::Simple' =>
		{
		'MAINTAINER'	=> 'schwern',
		'FILES'		=> q[lib/Test/Simple.pm lib/Test/Simple
				     t/lib/Test/Simple],
		'CPAN'		=> 1,
		},

	'Term::Cap' =>
		{
		'MAINTAINER'	=> 'jns',
		'FILES'		=> q[lib/Term/Cap.{pm,t}],
		'CPAN'		=> 1,
		},

	'threads' =>
		{
		'MAINTAINER' => 'arthur',
		'FILES'	 => q[ext/threads],
		'CPAN'		=> 1,
		},

	'Tie::File' =>
		{
		'MAINTAINER'	=> 'mjd',
		'FILES'		=> q[lib/Tie/File.pm lib/Tie/File],
		'CPAN'		=> 1,
		},

	'Time::HiRes' =>
		{
		'MAINTAINER'	=> 'jhi',
		'FILES'		=> q[ext/Time/HiRes],
		'CPAN'		=> 1,
		},

	'Time::Local' =>
		{
		'MAINTAINER'	=> 'autarch',
		'FILES'		=> q[lib/Time/Local.{pm,t}],
		'CPAN'		=> 1,
		},

	'Unicode::Collate' =>
		{
		'MAINTAINER'	=> 'sadahiro',
		'FILES'		=> q[lib/Unicode/Collate.pm
				     lib/Unicode/Collate],
		'CPAN'		=> 1,
		},

	'Unicode::Normalize' =>
		{
		'MAINTAINER'	=> 'sadahiro',
		'FILES'		=> q[ext/Unicode/Normalize],
		'CPAN'		=> 1,
		},

	'warnings' =>
		{
		'MAINTAINER'	=> 'pmarquess',
		'FILES'		=> q[warnings.pl lib/warnings.{pm,t}
				     lib/warnings t/lib/warnings],
		'CPAN'		=> 1,
		},

	);

1;
