use ExtUtils::MakeMaker;

WriteMakefile(
    'LINKTYPE'	=> 'static',
    'DEFINE'	=> '-DLIBC="$(LIBC)"',
    'SKIP'	=> [qw(dynamic dynamic_lib dynamic_bs)],
    'clean'	=> {FILES => 'DynaLoader.c'},
);


sub MY::postamble {
	'
DynaLoader.c: $(DLSRC)
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $(DLSRC) >tmp && mv tmp $@

# Perform very simple tests just to check for major gaffs.
# We can\'t do much more for platforms we are not executing on.
test-xs:
	for i in dl_*xs; \
	    do $(PERL) $(XSUBPP) $(XSUBPPARGS) $$i > /dev/null; \
	done
';
}

