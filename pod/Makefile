all: man

PERL = ../miniperl

POD = \
	perl.pod	\
	perlapi.pod	\
	perlbook.pod	\
	perlbot.pod	\
	perlcall.pod	\
	perldata.pod	\
	perldebug.pod	\
	perldiag.pod	\
	perlembed.pod	\
	perlform.pod	\
	perlfunc.pod	\
	perlguts.pod	\
	perlipc.pod	\
	perlmod.pod	\
	perlobj.pod	\
	perlop.pod	\
	perlovl.pod	\
	perlpod.pod	\
	perlre.pod	\
	perlref.pod	\
	perlrun.pod	\
	perlsec.pod	\
	perlstyle.pod	\
	perlsub.pod	\
	perlsyn.pod	\
	perltrap.pod	\
	perlvar.pod

MAN = \
	perl.man	\
	perlapi.man	\
	perlbook.man	\
	perlbot.man	\
	perlcall.man	\
	perldata.man	\
	perldebug.man	\
	perldiag.man	\
	perlembed.man	\
	perlform.man	\
	perlfunc.man	\
	perlguts.man	\
	perlipc.man	\
	perlmod.man	\
	perlobj.man	\
	perlop.man	\
	perlovl.man	\
	perlpod.man	\
	perlre.man	\
	perlref.man	\
	perlrun.man	\
	perlsec.man	\
	perlstyle.man	\
	perlsub.man	\
	perlsyn.man	\
	perltrap.man	\
	perlvar.man

HTML = \
	perl.html	\
	perlapi.html	\
	perlbook.html	\
	perlbot.html	\
	perlcall.html	\
	perldata.html	\
	perldebug.html	\
	perldiag.html	\
	perlembed.html	\
	perlform.html	\
	perlfunc.html	\
	perlguts.html	\
	perlipc.html	\
	perlmod.html	\
	perlobj.html	\
	perlop.html	\
	perlovl.html	\
	perlpod.html	\
	perlre.html	\
	perlref.html	\
	perlrun.html	\
	perlsec.html	\
	perlstyle.html	\
	perlsub.html	\
	perlsyn.html	\
	perltrap.html	\
	perlvar.html

man: $(MAN)

# pod2html runs on all the pods at once in order to build up
# cross-references.
html:
	$(PERL) pod2html *.pod

.SUFFIXES: .pod .man

.pod.man:
	$(PERL) pod2man $*.pod >$*.man

.SUFFIXES: .pod .html

.pod.html:
	$(PERL) pod2html $*.pod

clean:
	rm -f $(MAN) $(HTML)

realclean:	clean
	rm -f pod2man pod2latex pod2html

distclean:	realclean

# Dependencies.
pod2latex:	pod2latex.SH ../config.sh
	sh pod2latex.SH

pod2html:	pod2html.SH ../config.sh
	sh pod2html.SH

pod2man:	pod2man.SH ../config.sh
	sh pod2man.SH
