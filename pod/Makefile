CONVERTERS = pod2html pod2latex pod2man pod2text checkpods

all: $(CONVERTERS) man
PERL = ../miniperl

POD = \
	perl.pod	\
	perlnews.pod	\
	perldata.pod	\
	perlsyn.pod	\
	perlop.pod	\
	perlre.pod	\
	perlrun.pod	\
	perlfunc.pod	\
	perlvar.pod	\
	perlsub.pod	\
	perlmod.pod	\
	perlform.pod	\
	perllocale.pod	\
	perlref.pod	\
	perldsc.pod	\
	perllol.pod	\
	perltoot.pod	\
	perlobj.pod	\
	perltie.pod	\
	perlbot.pod	\
	perlipc.pod	\
	perldebug.pod	\
	perldiag.pod	\
	perlsec.pod	\
	perltrap.pod	\
	perlstyle.pod	\
	perlpod.pod	\
	perlbook.pod	\
	perlembed.pod	\
	perlapio.pod	\
	perlxs.pod	\
	perlxstut.pod	\
	perlguts.pod	\
	perlcall.pod	\
	perltoc.pod

MAN = \
	perl.man	\
	perlnews.man	\
	perldata.man	\
	perlsyn.man	\
	perlop.man	\
	perlre.man	\
	perlrun.man	\
	perlfunc.man	\
	perlvar.man	\
	perlsub.man	\
	perlmod.man	\
	perlform.man	\
	perllocale.man	\
	perlref.man	\
	perldsc.man	\
	perllol.man	\
	perltoot.man	\
	perlobj.man	\
	perltie.man	\
	perlbot.man	\
	perlipc.man	\
	perldebug.man	\
	perldiag.man	\
	perlsec.man	\
	perltrap.man	\
	perlstyle.man	\
	perlpod.man	\
	perlbook.man	\
	perlembed.man	\
	perlapio.man	\
	perlxs.man	\
	perlxstut.man	\
	perlguts.man	\
	perlcall.man	\
	perltoc.man

HTML = \
	perl.html	\
	perlnews.html	\
	perldata.html	\
	perlsyn.html	\
	perlop.html	\
	perlre.html	\
	perlrun.html	\
	perlfunc.html	\
	perlvar.html	\
	perlsub.html	\
	perlmod.html	\
	perlform.html	\
	perllocale.html	\
	perlref.html	\
	perldsc.html	\
	perllol.html	\
	perltoot.html	\
	perlobj.html	\
	perltie.html	\
	perlbot.html	\
	perlipc.html	\
	perldebug.html	\
	perldiag.html	\
	perlsec.html	\
	perltrap.html	\
	perlstyle.html	\
	perlpod.html	\
	perlbook.html	\
	perlembed.html	\
	perlapio.html	\
	perlxs.html	\
	perlxstut.html	\
	perlguts.html	\
	perlcall.html	\
	perltoc.html

TEX = \
	perl.tex	\
	perlnews.tex	\
	perldata.tex	\
	perlsyn.tex	\
	perlop.tex	\
	perlre.tex	\
	perlrun.tex	\
	perlfunc.tex	\
	perlvar.tex	\
	perlsub.tex	\
	perlmod.tex	\
	perlform.tex	\
	perllocale.tex	\
	perlref.tex	\
	perldsc.tex	\
	perllol.tex	\
	perltoot.tex	\
	perlobj.tex	\
	perltie.tex	\
	perlbot.tex	\
	perlipc.tex	\
	perldebug.tex	\
	perldiag.tex	\
	perlsec.tex	\
	perltrap.tex	\
	perlstyle.tex	\
	perlpod.tex	\
	perlbook.tex	\
	perlembed.tex	\
	perlapio.tex	\
	perlxs.tex	\
	perlxstut.tex	\
	perlguts.tex	\
	perlcall.tex	\
	perltoc.tex

man:  pod2man $(MAN)

# pod2html normally runs on all the pods at once in order to build up
# cross-references.
html: pod2html
	$(PERL) -I../lib pod2html $(POD)

tex:	pod2latex $(TEX)

toc:
	$(PERL) -I../lib buildtoc >perltoc.pod

.SUFFIXES: .pm .pod .man

.pm.man:     pod2man
	$(PERL) -I../lib pod2man $*.pm >$*.man

.pod.man:     pod2man
	$(PERL) -I../lib pod2man $*.pod >$*.man

.SUFFIXES: .mp .pod .html

.pm.html:    pod2html
	$(PERL) -I../lib pod2html $*.pod

.pod.html:    pod2html
	$(PERL) -I../lib pod2html $*.pod

.SUFFIXES: .pm .pod .tex

.pod.tex: pod2latex
	$(PERL) -I../lib pod2latex $*.pod

.pm.tex: pod2latex
	$(PERL) -I../lib pod2latex $*.pod

clean:
	rm -f $(MAN) $(HTML) $(TEX)
	rm -f *.aux *.log

realclean:	clean
	rm -f $(CONVERTERS)

distclean:	realclean

check:	checkpods
	@echo "checking..."; \
	$(PERL) -I../lib checkpods $(POD)

# Dependencies.
pod2latex:	pod2latex.PL ../lib/Config.pm
	$(PERL) -I../lib pod2latex.PL

pod2html:	pod2html.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2html.PL

pod2man:	pod2man.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2man.PL

pod2text:	pod2text.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2text.PL

checkpods:	checkpods.PL ../lib/Config.pm
	$(PERL) -I ../lib checkpods.PL


