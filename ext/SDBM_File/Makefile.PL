use ExtUtils::MakeMaker;

# The existence of the ./sdbm/Makefile.PL file causes MakeMaker
# to automatically include Makefile code for the targets
#	config, all, clean, realclean and sdbm/Makefile
# which perform the corresponding actions in the subdirectory.

WriteMakefile(
    'MYEXTLIB' => 'sdbm/libsdbm$(LIB_EXT)',
);


sub MY::postamble {
    '
$(MYEXTLIB): sdbm/Makefile
	cd sdbm; $(MAKE) all
';
}

