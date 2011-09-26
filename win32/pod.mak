HTMLROOT = /	# Change this to fix cross-references in HTML
POD2HTML_ARGS = --htmlroot=$(HTMLROOT) \
	    --podroot=.. --podpath=pod:lib:ext:vms \
	    --libpods=perlfunc:perlguts:perlvar:perlrun:perlop
POD2HTML = ../ext/Pod-Html/pod2html
POD2MAN = ../cpan/podlators/pod2man
POD2TEXT = ../cpan/podlators/pod2text
POD2LATEX = ../cpan/Pod-LaTeX/pod2latex
PODCHECKER = ../cpan/Pod-Parser/podchecker

all: html

PERL = ..\miniperl.exe
REALPERL = ..\perl.exe

ICWD = -I..\dist\Cwd

POD = \
	perl.pod	\
	perl5004delta.pod	\
	perl5005delta.pod	\
	perl5100delta.pod	\
	perl5101delta.pod	\
	perl5110delta.pod	\
	perl5111delta.pod	\
	perl5112delta.pod	\
	perl5113delta.pod	\
	perl5114delta.pod	\
	perl5115delta.pod	\
	perl5120delta.pod	\
	perl5121delta.pod	\
	perl5122delta.pod	\
	perl5123delta.pod	\
	perl5130delta.pod	\
	perl51310delta.pod	\
	perl51311delta.pod	\
	perl5131delta.pod	\
	perl5132delta.pod	\
	perl5133delta.pod	\
	perl5134delta.pod	\
	perl5135delta.pod	\
	perl5136delta.pod	\
	perl5137delta.pod	\
	perl5138delta.pod	\
	perl5139delta.pod	\
	perl5140delta.pod	\
	perl5141delta.pod	\
	perl5142delta.pod	\
	perl5143delta.pod	\
	perl561delta.pod	\
	perl56delta.pod	\
	perl570delta.pod	\
	perl571delta.pod	\
	perl572delta.pod	\
	perl573delta.pod	\
	perl581delta.pod	\
	perl582delta.pod	\
	perl583delta.pod	\
	perl584delta.pod	\
	perl585delta.pod	\
	perl586delta.pod	\
	perl587delta.pod	\
	perl588delta.pod	\
	perl589delta.pod	\
	perl58delta.pod	\
	perl590delta.pod	\
	perl591delta.pod	\
	perl592delta.pod	\
	perl593delta.pod	\
	perl594delta.pod	\
	perl595delta.pod	\
	perlapi.pod	\
	perlapio.pod	\
	perlartistic.pod	\
	perlbook.pod	\
	perlboot.pod	\
	perlbot.pod	\
	perlcall.pod	\
	perlcheat.pod	\
	perlclib.pod	\
	perlcommunity.pod	\
	perlcompile.pod	\
	perldata.pod	\
	perldbmfilter.pod	\
	perldebguts.pod	\
	perldebtut.pod	\
	perldebug.pod	\
	perldelta.pod	\
	perldiag.pod	\
	perldoc.pod	\
	perldsc.pod	\
	perlebcdic.pod	\
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
	perlgit.pod	\
	perlglossary.pod	\
	perlgpl.pod	\
	perlguts.pod	\
	perlhack.pod	\
	perlhacktips.pod	\
	perlhacktut.pod	\
	perlhist.pod	\
	perlintern.pod	\
	perlinterp.pod	\
	perlintro.pod	\
	perliol.pod	\
	perlipc.pod	\
	perllexwarn.pod	\
	perllocale.pod	\
	perllol.pod	\
	perlmod.pod	\
	perlmodinstall.pod	\
	perlmodlib.pod	\
	perlmodstyle.pod	\
	perlmroapi.pod	\
	perlnewmod.pod	\
	perlnumber.pod	\
	perlobj.pod	\
	perlop.pod	\
	perlopentut.pod	\
	perlpacktut.pod	\
	perlperf.pod	\
	perlpod.pod	\
	perlpodspec.pod	\
	perlpodstyle.pod	\
	perlpolicy.pod	\
	perlport.pod	\
	perlpragma.pod	\
	perlre.pod	\
	perlreapi.pod	\
	perlrebackslash.pod	\
	perlrecharclass.pod	\
	perlref.pod	\
	perlreftut.pod	\
	perlreguts.pod	\
	perlrequick.pod	\
	perlreref.pod	\
	perlretut.pod	\
	perlrun.pod	\
	perlsec.pod	\
	perlsource.pod	\
	perlstyle.pod	\
	perlsub.pod	\
	perlsyn.pod	\
	perlthrtut.pod	\
	perltie.pod	\
	perltoc.pod	\
	perltodo.pod	\
	perltooc.pod	\
	perltoot.pod	\
	perltrap.pod	\
	perlunicode.pod	\
	perlunifaq.pod	\
	perluniintro.pod	\
	perluniprops.pod	\
	perlunitut.pod	\
	perlutil.pod	\
	perlvar.pod	\
	perlvms.pod	\
	perlxs.pod	\
	perlxstut.pod	

MAN = \
	perl.man	\
	perl5004delta.man	\
	perl5005delta.man	\
	perl5100delta.man	\
	perl5101delta.man	\
	perl5110delta.man	\
	perl5111delta.man	\
	perl5112delta.man	\
	perl5113delta.man	\
	perl5114delta.man	\
	perl5115delta.man	\
	perl5120delta.man	\
	perl5121delta.man	\
	perl5122delta.man	\
	perl5123delta.man	\
	perl5130delta.man	\
	perl51310delta.man	\
	perl51311delta.man	\
	perl5131delta.man	\
	perl5132delta.man	\
	perl5133delta.man	\
	perl5134delta.man	\
	perl5135delta.man	\
	perl5136delta.man	\
	perl5137delta.man	\
	perl5138delta.man	\
	perl5139delta.man	\
	perl5140delta.man	\
	perl5141delta.man	\
	perl5142delta.man	\
	perl5143delta.man	\
	perl561delta.man	\
	perl56delta.man	\
	perl570delta.man	\
	perl571delta.man	\
	perl572delta.man	\
	perl573delta.man	\
	perl581delta.man	\
	perl582delta.man	\
	perl583delta.man	\
	perl584delta.man	\
	perl585delta.man	\
	perl586delta.man	\
	perl587delta.man	\
	perl588delta.man	\
	perl589delta.man	\
	perl58delta.man	\
	perl590delta.man	\
	perl591delta.man	\
	perl592delta.man	\
	perl593delta.man	\
	perl594delta.man	\
	perl595delta.man	\
	perlapi.man	\
	perlapio.man	\
	perlartistic.man	\
	perlbook.man	\
	perlboot.man	\
	perlbot.man	\
	perlcall.man	\
	perlcheat.man	\
	perlclib.man	\
	perlcommunity.man	\
	perlcompile.man	\
	perldata.man	\
	perldbmfilter.man	\
	perldebguts.man	\
	perldebtut.man	\
	perldebug.man	\
	perldelta.man	\
	perldiag.man	\
	perldoc.man	\
	perldsc.man	\
	perlebcdic.man	\
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
	perlgit.man	\
	perlglossary.man	\
	perlgpl.man	\
	perlguts.man	\
	perlhack.man	\
	perlhacktips.man	\
	perlhacktut.man	\
	perlhist.man	\
	perlintern.man	\
	perlinterp.man	\
	perlintro.man	\
	perliol.man	\
	perlipc.man	\
	perllexwarn.man	\
	perllocale.man	\
	perllol.man	\
	perlmod.man	\
	perlmodinstall.man	\
	perlmodlib.man	\
	perlmodstyle.man	\
	perlmroapi.man	\
	perlnewmod.man	\
	perlnumber.man	\
	perlobj.man	\
	perlop.man	\
	perlopentut.man	\
	perlpacktut.man	\
	perlperf.man	\
	perlpod.man	\
	perlpodspec.man	\
	perlpodstyle.man	\
	perlpolicy.man	\
	perlport.man	\
	perlpragma.man	\
	perlre.man	\
	perlreapi.man	\
	perlrebackslash.man	\
	perlrecharclass.man	\
	perlref.man	\
	perlreftut.man	\
	perlreguts.man	\
	perlrequick.man	\
	perlreref.man	\
	perlretut.man	\
	perlrun.man	\
	perlsec.man	\
	perlsource.man	\
	perlstyle.man	\
	perlsub.man	\
	perlsyn.man	\
	perlthrtut.man	\
	perltie.man	\
	perltoc.man	\
	perltodo.man	\
	perltooc.man	\
	perltoot.man	\
	perltrap.man	\
	perlunicode.man	\
	perlunifaq.man	\
	perluniintro.man	\
	perluniprops.man	\
	perlunitut.man	\
	perlutil.man	\
	perlvar.man	\
	perlvms.man	\
	perlxs.man	\
	perlxstut.man	

HTML = \
	perl.html	\
	perl5004delta.html	\
	perl5005delta.html	\
	perl5100delta.html	\
	perl5101delta.html	\
	perl5110delta.html	\
	perl5111delta.html	\
	perl5112delta.html	\
	perl5113delta.html	\
	perl5114delta.html	\
	perl5115delta.html	\
	perl5120delta.html	\
	perl5121delta.html	\
	perl5122delta.html	\
	perl5123delta.html	\
	perl5130delta.html	\
	perl51310delta.html	\
	perl51311delta.html	\
	perl5131delta.html	\
	perl5132delta.html	\
	perl5133delta.html	\
	perl5134delta.html	\
	perl5135delta.html	\
	perl5136delta.html	\
	perl5137delta.html	\
	perl5138delta.html	\
	perl5139delta.html	\
	perl5140delta.html	\
	perl5141delta.html	\
	perl5142delta.html	\
	perl5143delta.html	\
	perl561delta.html	\
	perl56delta.html	\
	perl570delta.html	\
	perl571delta.html	\
	perl572delta.html	\
	perl573delta.html	\
	perl581delta.html	\
	perl582delta.html	\
	perl583delta.html	\
	perl584delta.html	\
	perl585delta.html	\
	perl586delta.html	\
	perl587delta.html	\
	perl588delta.html	\
	perl589delta.html	\
	perl58delta.html	\
	perl590delta.html	\
	perl591delta.html	\
	perl592delta.html	\
	perl593delta.html	\
	perl594delta.html	\
	perl595delta.html	\
	perlapi.html	\
	perlapio.html	\
	perlartistic.html	\
	perlbook.html	\
	perlboot.html	\
	perlbot.html	\
	perlcall.html	\
	perlcheat.html	\
	perlclib.html	\
	perlcommunity.html	\
	perlcompile.html	\
	perldata.html	\
	perldbmfilter.html	\
	perldebguts.html	\
	perldebtut.html	\
	perldebug.html	\
	perldelta.html	\
	perldiag.html	\
	perldoc.html	\
	perldsc.html	\
	perlebcdic.html	\
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
	perlgit.html	\
	perlglossary.html	\
	perlgpl.html	\
	perlguts.html	\
	perlhack.html	\
	perlhacktips.html	\
	perlhacktut.html	\
	perlhist.html	\
	perlintern.html	\
	perlinterp.html	\
	perlintro.html	\
	perliol.html	\
	perlipc.html	\
	perllexwarn.html	\
	perllocale.html	\
	perllol.html	\
	perlmod.html	\
	perlmodinstall.html	\
	perlmodlib.html	\
	perlmodstyle.html	\
	perlmroapi.html	\
	perlnewmod.html	\
	perlnumber.html	\
	perlobj.html	\
	perlop.html	\
	perlopentut.html	\
	perlpacktut.html	\
	perlperf.html	\
	perlpod.html	\
	perlpodspec.html	\
	perlpodstyle.html	\
	perlpolicy.html	\
	perlport.html	\
	perlpragma.html	\
	perlre.html	\
	perlreapi.html	\
	perlrebackslash.html	\
	perlrecharclass.html	\
	perlref.html	\
	perlreftut.html	\
	perlreguts.html	\
	perlrequick.html	\
	perlreref.html	\
	perlretut.html	\
	perlrun.html	\
	perlsec.html	\
	perlsource.html	\
	perlstyle.html	\
	perlsub.html	\
	perlsyn.html	\
	perlthrtut.html	\
	perltie.html	\
	perltodo.html	\
	perltooc.html	\
	perltoot.html	\
	perltrap.html	\
	perlunicode.html	\
	perlunifaq.html	\
	perluniintro.html	\
	perluniprops.html	\
	perlunitut.html	\
	perlutil.html	\
	perlvar.html	\
	perlvms.html	\
	perlxs.html	\
	perlxstut.html	
# not perltoc.html

TEX = \
	perl.tex	\
	perl5004delta.tex	\
	perl5005delta.tex	\
	perl5100delta.tex	\
	perl5101delta.tex	\
	perl5110delta.tex	\
	perl5111delta.tex	\
	perl5112delta.tex	\
	perl5113delta.tex	\
	perl5114delta.tex	\
	perl5115delta.tex	\
	perl5120delta.tex	\
	perl5121delta.tex	\
	perl5122delta.tex	\
	perl5123delta.tex	\
	perl5130delta.tex	\
	perl51310delta.tex	\
	perl51311delta.tex	\
	perl5131delta.tex	\
	perl5132delta.tex	\
	perl5133delta.tex	\
	perl5134delta.tex	\
	perl5135delta.tex	\
	perl5136delta.tex	\
	perl5137delta.tex	\
	perl5138delta.tex	\
	perl5139delta.tex	\
	perl5140delta.tex	\
	perl5141delta.tex	\
	perl5142delta.tex	\
	perl5143delta.tex	\
	perl561delta.tex	\
	perl56delta.tex	\
	perl570delta.tex	\
	perl571delta.tex	\
	perl572delta.tex	\
	perl573delta.tex	\
	perl581delta.tex	\
	perl582delta.tex	\
	perl583delta.tex	\
	perl584delta.tex	\
	perl585delta.tex	\
	perl586delta.tex	\
	perl587delta.tex	\
	perl588delta.tex	\
	perl589delta.tex	\
	perl58delta.tex	\
	perl590delta.tex	\
	perl591delta.tex	\
	perl592delta.tex	\
	perl593delta.tex	\
	perl594delta.tex	\
	perl595delta.tex	\
	perlapi.tex	\
	perlapio.tex	\
	perlartistic.tex	\
	perlbook.tex	\
	perlboot.tex	\
	perlbot.tex	\
	perlcall.tex	\
	perlcheat.tex	\
	perlclib.tex	\
	perlcommunity.tex	\
	perlcompile.tex	\
	perldata.tex	\
	perldbmfilter.tex	\
	perldebguts.tex	\
	perldebtut.tex	\
	perldebug.tex	\
	perldelta.tex	\
	perldiag.tex	\
	perldoc.tex	\
	perldsc.tex	\
	perlebcdic.tex	\
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
	perlgit.tex	\
	perlglossary.tex	\
	perlgpl.tex	\
	perlguts.tex	\
	perlhack.tex	\
	perlhacktips.tex	\
	perlhacktut.tex	\
	perlhist.tex	\
	perlintern.tex	\
	perlinterp.tex	\
	perlintro.tex	\
	perliol.tex	\
	perlipc.tex	\
	perllexwarn.tex	\
	perllocale.tex	\
	perllol.tex	\
	perlmod.tex	\
	perlmodinstall.tex	\
	perlmodlib.tex	\
	perlmodstyle.tex	\
	perlmroapi.tex	\
	perlnewmod.tex	\
	perlnumber.tex	\
	perlobj.tex	\
	perlop.tex	\
	perlopentut.tex	\
	perlpacktut.tex	\
	perlperf.tex	\
	perlpod.tex	\
	perlpodspec.tex	\
	perlpodstyle.tex	\
	perlpolicy.tex	\
	perlport.tex	\
	perlpragma.tex	\
	perlre.tex	\
	perlreapi.tex	\
	perlrebackslash.tex	\
	perlrecharclass.tex	\
	perlref.tex	\
	perlreftut.tex	\
	perlreguts.tex	\
	perlrequick.tex	\
	perlreref.tex	\
	perlretut.tex	\
	perlrun.tex	\
	perlsec.tex	\
	perlsource.tex	\
	perlstyle.tex	\
	perlsub.tex	\
	perlsyn.tex	\
	perlthrtut.tex	\
	perltie.tex	\
	perltoc.tex	\
	perltodo.tex	\
	perltooc.tex	\
	perltoot.tex	\
	perltrap.tex	\
	perlunicode.tex	\
	perlunifaq.tex	\
	perluniintro.tex	\
	perluniprops.tex	\
	perlunitut.tex	\
	perlutil.tex	\
	perlvar.tex	\
	perlvms.tex	\
	perlxs.tex	\
	perlxstut.tex	

man:	$(POD2MAN) $(MAN)

html:	$(POD2HTML) $(HTML)

tex:	$(POD2LATEX) $(TEX)

toc:
	$(PERL) -I../lib buildtoc >perltoc.pod

.SUFFIXES: .pm .pod

.SUFFIXES: .man

.pm.man:
	$(PERL) -I../lib $(POD2MAN) $*.pm >$*.man

.pod.man:
	$(PERL) -I../lib $(POD2MAN) $*.pod >$*.man

.SUFFIXES: .html

.pm.html:
	$(PERL) -I../lib $(POD2HTML) $(POD2HTML_ARGS) --infile=$*.pm --outfile=$*.html

.pod.html:
	$(PERL) -I../lib $(POD2HTML) $(POD2HTML_ARGS) --infile=$*.pod --outfile=$*.html

.SUFFIXES: .tex

.pm.tex:
	$(PERL) -I../lib $(POD2LATEX) $*.pm

.pod.tex:
	$(PERL) -I../lib $(POD2LATEX) $*.pod

clean:
	rm -f $(MAN)
	rm -f $(HTML)
	rm -f $(TEX)
	rm -f pod2html-*cache
	rm -f *.aux *.log *.exe

realclean:	clean

distclean:	realclean

check:	$(PODCHECKER)
	@echo "checking..."; \
	$(PERL) -I../lib $(PODCHECKER) $(POD)
