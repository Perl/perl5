CONVERTERS = pod2html pod2latex pod2man pod2text checkpods \
		pod2usage podchecker podselect

HTMLROOT = /	# Change this to fix cross-references in HTML
POD2HTML = pod2html \
	    --htmlroot=$(HTMLROOT) \
	    --podroot=.. --podpath=pod:lib:ext:vms \
	    --libpods=perlfunc:perlguts:perlvar:perlrun:perlop

all: $(CONVERTERS) man

converters: $(CONVERTERS)

PERL = ../miniperl
REALPERL = ../perl

POD = \
	perl.pod	\
	perl5004delta.pod	\
	perl5005delta.pod	\
	perl56delta.pod	\
	perlapi.pod	\
	perlapio.pod	\
	perlbook.pod	\
	perlboot.pod	\
	perlbot.pod	\
	perlcall.pod	\
	perlcompile.pod	\
	perldata.pod	\
	perldbmfilter.pod	\
	perldebguts.pod	\
	perldebug.pod	\
	perldelta.pod	\
	perldiag.pod	\
	perldsc.pod	\
	perlembed.pod	\
	perlfaq.pod	\
	perlfaq1.pod	\
	perlfaq2.pod	\
	perlfaq3.pod	\
	perlfaq4.pod	\
	perlfaq5.pod	\
	perlfaq6.pod	\
	perlfaq7.pod	\
	perlfaq8.pod	\
	perlfaq9.pod	\
	perlfilter.pod	\
	perlfork.pod	\
	perlform.pod	\
	perlfunc.pod	\
	perlguts.pod	\
	perlhack.pod	\
	perlhist.pod	\
	perlintern.pod	\
	perlipc.pod	\
	perllexwarn.pod	\
	perllocale.pod	\
	perllol.pod	\
	perlmod.pod	\
	perlmodinstall.pod	\
	perlmodlib.pod	\
	perlnewmod.pod	\
	perlnumber.pod	\
	perlobj.pod	\
	perlop.pod	\
	perlopentut.pod	\
	perlpod.pod	\
	perlport.pod	\
	perlre.pod	\
	perlref.pod	\
	perlreftut.pod	\
	perlrequick.pod	\
	perlretut.pod	\
	perlrun.pod	\
	perlsec.pod	\
	perlstyle.pod	\
	perlsub.pod	\
	perlsyn.pod	\
	perlthrtut.pod	\
	perltie.pod	\
	perltoc.pod	\
	perltodo.pod	\
	perltoot.pod	\
	perltootc.pod	\
	perltrap.pod	\
	perlunicode.pod	\
	perlutil.pod	\
	perlvar.pod	\
	perlxs.pod	\
	perlxstut.pod

MAN = \
	perl.man	\
	perl5004delta.man	\
	perl5005delta.man	\
	perl56delta.man	\
	perlapi.man	\
	perlapio.man	\
	perlbook.man	\
	perlboot.man	\
	perlbot.man	\
	perlcall.man	\
	perlcompile.man	\
	perldata.man	\
	perldbmfilter.man	\
	perldebguts.man	\
	perldebug.man	\
	perldelta.man	\
	perldiag.man	\
	perldsc.man	\
	perlembed.man	\
	perlfaq.man	\
	perlfaq1.man	\
	perlfaq2.man	\
	perlfaq3.man	\
	perlfaq4.man	\
	perlfaq5.man	\
	perlfaq6.man	\
	perlfaq7.man	\
	perlfaq8.man	\
	perlfaq9.man	\
	perlfilter.man	\
	perlfork.man	\
	perlform.man	\
	perlfunc.man	\
	perlguts.man	\
	perlhack.man	\
	perlhist.man	\
	perlintern.man	\
	perlipc.man	\
	perllexwarn.man	\
	perllocale.man	\
	perllol.man	\
	perlmod.man	\
	perlmodinstall.man	\
	perlmodlib.man	\
	perlnewmod.man	\
	perlnumber.man	\
	perlobj.man	\
	perlop.man	\
	perlopentut.man	\
	perlpod.man	\
	perlport.man	\
	perlre.man	\
	perlref.man	\
	perlreftut.man	\
	perlrequick.man	\
	perlretut.man	\
	perlrun.man	\
	perlsec.man	\
	perlstyle.man	\
	perlsub.man	\
	perlsyn.man	\
	perlthrtut.man	\
	perltie.man	\
	perltoc.man	\
	perltodo.man	\
	perltoot.man	\
	perltootc.man	\
	perltrap.man	\
	perlunicode.man	\
	perlutil.man	\
	perlvar.man	\
	perlxs.man	\
	perlxstut.man

HTML = \
	perl.html	\
	perl5004delta.html	\
	perl5005delta.html	\
	perl56delta.html	\
	perlapi.html	\
	perlapio.html	\
	perlbook.html	\
	perlboot.html	\
	perlbot.html	\
	perlcall.html	\
	perlcompile.html	\
	perldata.html	\
	perldbmfilter.html	\
	perldebguts.html	\
	perldebug.html	\
	perldelta.html	\
	perldiag.html	\
	perldsc.html	\
	perlembed.html	\
	perlfaq.html	\
	perlfaq1.html	\
	perlfaq2.html	\
	perlfaq3.html	\
	perlfaq4.html	\
	perlfaq5.html	\
	perlfaq6.html	\
	perlfaq7.html	\
	perlfaq8.html	\
	perlfaq9.html	\
	perlfilter.html	\
	perlfork.html	\
	perlform.html	\
	perlfunc.html	\
	perlguts.html	\
	perlhack.html	\
	perlhist.html	\
	perlintern.html	\
	perlipc.html	\
	perllexwarn.html	\
	perllocale.html	\
	perllol.html	\
	perlmod.html	\
	perlmodinstall.html	\
	perlmodlib.html	\
	perlnewmod.html	\
	perlnumber.html	\
	perlobj.html	\
	perlop.html	\
	perlopentut.html	\
	perlpod.html	\
	perlport.html	\
	perlre.html	\
	perlref.html	\
	perlreftut.html	\
	perlrequick.html	\
	perlretut.html	\
	perlrun.html	\
	perlsec.html	\
	perlstyle.html	\
	perlsub.html	\
	perlsyn.html	\
	perlthrtut.html	\
	perltie.html	\
	perltodo.html	\
	perltoot.html	\
	perltootc.html	\
	perltrap.html	\
	perlunicode.html	\
	perlutil.html	\
	perlvar.html	\
	perlxs.html	\
	perlxstut.html

# not perltoc.html

TEX = \
	perl.tex	\
	perl5004delta.tex	\
	perl5005delta.tex	\
	perl56delta.tex	\
	perlapi.tex	\
	perlapio.tex	\
	perlbook.tex	\
	perlboot.tex	\
	perlbot.tex	\
	perlcall.tex	\
	perlcompile.tex	\
	perldata.tex	\
	perldbmfilter.tex	\
	perldebguts.tex	\
	perldebug.tex	\
	perldelta.tex	\
	perldiag.tex	\
	perldsc.tex	\
	perlembed.tex	\
	perlfaq.tex	\
	perlfaq1.tex	\
	perlfaq2.tex	\
	perlfaq3.tex	\
	perlfaq4.tex	\
	perlfaq5.tex	\
	perlfaq6.tex	\
	perlfaq7.tex	\
	perlfaq8.tex	\
	perlfaq9.tex	\
	perlfilter.tex	\
	perlfork.tex	\
	perlform.tex	\
	perlfunc.tex	\
	perlguts.tex	\
	perlhack.tex	\
	perlhist.tex	\
	perlintern.tex	\
	perlipc.tex	\
	perllexwarn.tex	\
	perllocale.tex	\
	perllol.tex	\
	perlmod.tex	\
	perlmodinstall.tex	\
	perlmodlib.tex	\
	perlnewmod.tex	\
	perlnumber.tex	\
	perlobj.tex	\
	perlop.tex	\
	perlopentut.tex	\
	perlpod.tex	\
	perlport.tex	\
	perlre.tex	\
	perlref.tex	\
	perlreftut.tex	\
	perlrequick.tex	\
	perlretut.tex	\
	perlrun.tex	\
	perlsec.tex	\
	perlstyle.tex	\
	perlsub.tex	\
	perlsyn.tex	\
	perlthrtut.tex	\
	perltie.tex	\
	perltoc.tex	\
	perltodo.tex	\
	perltoot.tex	\
	perltootc.tex	\
	perltrap.tex	\
	perlunicode.tex	\
	perlutil.tex	\
	perlvar.tex	\
	perlxs.tex	\
	perlxstut.tex

man:	pod2man $(MAN)

html:	pod2html $(HTML)

tex:	pod2latex $(TEX)

toc:
	$(PERL) -I../lib buildtoc >perltoc.pod

.SUFFIXES: .pm .pod

.SUFFIXES: .man

.pm.man:     pod2man
	$(PERL) -I../lib pod2man $*.pm >$*.man

.pod.man:     pod2man
	$(PERL) -I../lib pod2man $*.pod >$*.man

.SUFFIXES: .html

.pm.html:    pod2html
	$(PERL) -I../lib $(POD2HTML) --infile=$*.pm --outfile=$*.html

.pod.html:    pod2html
	$(PERL) -I../lib $(POD2HTML) --infile=$*.pod --outfile=$*.html

.SUFFIXES: .tex

.pm.tex: pod2latex
	$(PERL) -I../lib pod2latex $*.pm

.pod.tex: pod2latex
	$(PERL) -I../lib pod2latex $*.pod

clean:
	rm -f $(MAN)
	rm -f $(HTML)
	rm -f $(TEX)
	rm -f pod2html-*cache
	rm -f *.aux *.log *.exe

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

pod2usage:	pod2usage.PL ../lib/Config.pm
	$(PERL) -I ../lib pod2usage.PL

podchecker:	podchecker.PL ../lib/Config.pm
	$(PERL) -I ../lib podchecker.PL

podselect:	podselect.PL ../lib/Config.pm
	$(PERL) -I ../lib podselect.PL

perlmodlib.pod:	$(PERL) perlmodlib.PL ../mv-if-diff
	rm -f perlmodlib.tmp
	$(PERL) -I ../lib perlmodlib.PL
	sh ../mv-if-diff perlmodlib.tmp perlmodlib.pod

compile: all
	$(REALPERL) -I../lib ../utils/perlcc -regex 's/$$/.exe/' pod2latex pod2man pod2text checkpods -prog -verbose dcf -log ../compilelog;

