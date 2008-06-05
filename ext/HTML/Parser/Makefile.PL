require 5.006;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'HTML::Parser',
    VERSION_FROM => 'Parser.pm',
    H            => [ "hparser.h", "hctype.h", "tokenpos.h", "pfunc.h",
		      "hparser.c", "util.c",
		    ],
    PREREQ_PM    => {
		      'HTML::Tagset' => 3,
                      'Test::More' => 0,    # only needed to run 'make test'
                    },
    DEFINE       => "-DMARKED_SECTION",
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean        => { FILES => 'hctype.h pfunc.h' },
);


sub MY::postamble
{
    '
pfunc.h : mkpfunc
	$(PERL) mkpfunc >pfunc.h

hctype.h : mkhctype
	$(PERL) mkhctype >hctype.h
'
}
