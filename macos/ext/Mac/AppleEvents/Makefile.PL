use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::AppleEvents),
	'VERSION_FROM'		=> 'AppleEvents.pm',
	'LINKTYPE'		=> 'static dynamic',
	'MACLIBS_SHARED'	=> '"::::::AEGizmos:AEGizmos4Perl.shlb.PPC" ',
	'OBJECT'		=> 'AppleEvents.c.o PerlAEUtils.cp.o',
	'INC'			=> '-i $(PERL_SRC):AEGizmos:include:'
);
