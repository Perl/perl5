diff -cr ..\perl5os2.patch\perl5.001m.andy/Makefile.SH ./Makefile.SH
*** ../perl5os2.patch/perl5.001m.andy/Makefile.SH	Mon Oct 09 21:40:46 1995
--- ./Makefile.SH	Thu Sep 28 00:13:40 1995
***************
*** 22,27 ****
--- 22,31 ----
  *) suidperl='';;
  esac
  
+ # In case Configure is not patched:
+ : ${obj_ext=.o} ${obj_ext_regexp='\.o'} ${lib_ext=.a} ${ar=ar} ${firstmakefile=makefile}
+ : ${exe_ext=} ${cldlibs="$libs $cryptlib"}
+ 
  shrpenv=""
  case "$d_shrplib" in
  *define*)
***************
*** 31,43 ****
       *[0-9]) plibsuf=.$so.$patchlevel;;
       *)	    plibsuf=.$so;;
      esac
      case "$shrpdir" in
       /usr/lib)	;;
       "")	;;
       *)		shrpenv="env LD_RUN_PATH=$shrpdir";;
      esac
      pldlflags="$cccdlflags";;
! *)  plibsuf=.a
      pldlflags="";;
  esac
  
--- 35,48 ----
       *[0-9]) plibsuf=.$so.$patchlevel;;
       *)	    plibsuf=.$so;;
      esac
+     if test "x$plibext" != "x" ; then  plibsuf=$plibext d_shrplib=custom ; fi
      case "$shrpdir" in
       /usr/lib)	;;
       "")	;;
       *)		shrpenv="env LD_RUN_PATH=$shrpdir";;
      esac
      pldlflags="$cccdlflags";;
! *)  plibsuf=$lib_ext
      pldlflags="";;
  esac
  
***************
*** 53,59 ****
  static_ai_list=' '
  for f in $static_ext; do
  	base=`echo "$f" | sed 's/.*\///'`
! 	static_list="$static_list lib/auto/$f/$base.a"
  	if test -f ext/$f/AutoInit.c; then
  	    static_ai_list="$static_ai_list ext/$f/AutoInit.c"
  	fi
--- 58,64 ----
  static_ai_list=' '
  for f in $static_ext; do
  	base=`echo "$f" | sed 's/.*\///'`
! 	static_list="$static_list lib/auto/$f/$base\$(A)"
  	if test -f ext/$f/AutoInit.c; then
  	    static_ai_list="$static_ai_list ext/$f/AutoInit.c"
  	fi
***************
*** 115,129 ****
  static_ext = $static_list
  ext = \$(dynamic_ext) \$(static_ext)
  static_ext_autoinit = $static_ai_list
! DYNALOADER = lib/auto/DynaLoader/DynaLoader.a
! 
  
  libs = $libs $cryptlib
  
  public = perl $suidperl
  
  shellflags = $shellflags
  
  ## To use an alternate make, set \$altmake in config.sh.
  MAKE = ${altmake-make}
  !GROK!THIS!
--- 120,152 ----
  static_ext = $static_list
  ext = \$(dynamic_ext) \$(static_ext)
  static_ext_autoinit = $static_ai_list
! DYNALOADER = lib/auto/DynaLoader/DynaLoader\$(A)
  
  libs = $libs $cryptlib
+ cldlibs = $cldlibs
  
  public = perl $suidperl
  
  shellflags = $shellflags
  
+ ## To make it possible a build on a case-unsensitive filesystem
+ 
+ firstmakefile = $firstmakefile
+ 
+ ## Architecture-specific objects
+ 
+ archobjs = $archobjs
+ 
+ ## Extention of object files
+ 
+ O = $obj_ext
+ O_REGEXP = $obj_ext_regexp
+ A = $lib_ext
+ AR = $ar
+ exe_ext = $exe_ext
+ 
+ .SUFFIXES: .c \$(O)
+ 
  ## To use an alternate make, set \$altmake in config.sh.
  MAKE = ${altmake-make}
  !GROK!THIS!
***************
*** 153,163 ****
  
  c = $(c1) $(c2) $(c3) miniperlmain.c perlmain.c
  
! obj1 = $(mallocobj) gv.o toke.o perly.o op.o regcomp.o dump.o util.o mg.o
! obj2 = hv.o av.o run.o pp_hot.o sv.o pp.o scope.o pp_ctl.o pp_sys.o
! obj3 = doop.o doio.o regexec.o taint.o deb.o globals.o
  
! obj = $(obj1) $(obj2) $(obj3)
  
  # Once perl has been Configure'd and built ok you build different
  # perl variants (Debugging, Embedded, Multiplicity etc) by saying:
--- 175,185 ----
  
  c = $(c1) $(c2) $(c3) miniperlmain.c perlmain.c
  
! obj1 = $(mallocobj) gv$(O) toke$(O) perly$(O) op$(O) regcomp$(O) dump$(O) util$(O) mg$(O)
! obj2 = hv$(O) av$(O) run$(O) pp_hot$(O) sv$(O) pp$(O) scope$(O) pp_ctl$(O) pp_sys$(O)
! obj3 = doop$(O) doio$(O) regexec$(O) taint$(O) deb$(O) globals$(O)
  
! obj = $(obj1) $(obj2) $(obj3) $(archobjs)
  
  # Once perl has been Configure'd and built ok you build different
  # perl variants (Debugging, Embedded, Multiplicity etc) by saying:
***************
*** 175,184 ****
  # grrr
  SHELL = /bin/sh
  
! .c.o:
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
! all: makefile miniperl $(private) $(public) $(dynamic_ext)
  	@echo " "; echo "	Making x2p stuff"; cd x2p; $(MAKE) all
  	
  # This is now done by installman only if you actually want the man pages.
--- 197,206 ----
  # grrr
  SHELL = /bin/sh
  
! .c$(O):
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
! all: $(firstmakefile) miniperl $(private) $(public) $(dynamic_ext)
  	@echo " "; echo "	Making x2p stuff"; cd x2p; $(MAKE) all
  	
  # This is now done by installman only if you actually want the man pages.
***************
*** 187,208 ****
  # Phony target to force checking subdirectories.
  # Apparently some makes require an action for the FORCE target.
  FORCE:
! 	@true
  
  # The $& notation tells Sequent machines that it can do a parallel make,
  # and is harmless otherwise.
  
! miniperl: $& miniperlmain.o $(perllib)
! 	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain.o $(perllib) $(libs)
  
! miniperlmain.o: miniperlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
! perlmain.c: miniperlmain.c config.sh makefile $(static_ext_autoinit)
  	sh writemain $(DYNALOADER) $(static_ext) > tmp
  	sh mv-if-diff tmp perlmain.c
  
! perlmain.o: perlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  # The file ext.libs is a list of libraries that must be linked in
--- 209,230 ----
  # Phony target to force checking subdirectories.
  # Apparently some makes require an action for the FORCE target.
  FORCE:
! 	@sh -c true
  
  # The $& notation tells Sequent machines that it can do a parallel make,
  # and is harmless otherwise.
  
! miniperl: $& miniperlmain$(O) $(perllib)
! 	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain$(O) $(perllib) $(cldlibs)
  
! miniperlmain$(O): miniperlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
! perlmain.c: miniperlmain.c config.sh $(firstmakefile) $(static_ext_autoinit)
  	sh writemain $(DYNALOADER) $(static_ext) > tmp
  	sh mv-if-diff tmp perlmain.c
  
! perlmain$(O): perlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  # The file ext.libs is a list of libraries that must be linked in
***************
*** 211,238 ****
  ext.libs: $(static_ext)
  	-@test -f ext.libs || touch ext.libs
  
! perl: $& perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(SHRPENV) $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o perl perlmain.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! pureperl: $& perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	purify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o pureperl perlmain.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
- quantperl: $& perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
- 	quantify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o quantperl perlmain.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! $(perllib): $& perl.o $(obj)
  !NO!SUBS!
  
  case "$d_shrplib" in
  *define*)
  $spitshell >>Makefile <<'!NO!SUBS!'
! 	$(LD) $(LDDLFLAGS) -o $@ perl.o $(obj)
  !NO!SUBS!
  ;;
  *)
  $spitshell >>Makefile <<'!NO!SUBS!'
  	rm -f $(perllib)
! 	ar rcu $(perllib) perl.o $(obj)
  	@$(ranlib) $(perllib)
  !NO!SUBS!
  ;;
--- 233,280 ----
  ext.libs: $(static_ext)
  	-@test -f ext.libs || touch ext.libs
  
! perl: $& perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(SHRPENV) $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o perl perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
! 
! pureperl: $& perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	purify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o pureperl perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! quantperl: $& perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	quantify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o quantperl perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
! 
! !NO!SUBS!
  
  
! case "$d_shrplib" in
! custom) ;;
! *)
! $spitshell >>Makefile <<'!NO!SUBS!'
! $(perllib): $& perl$(O) $(obj)
  !NO!SUBS!
+ esac
  
  case "$d_shrplib" in
  *define*)
  $spitshell >>Makefile <<'!NO!SUBS!'
! 	$(LD) $(LDDLFLAGS) -o $@ perl$(O) $(obj)
  !NO!SUBS!
  ;;
+ custom)
+ if test -r $osname/Makefile.SH ; then 
+   . $osname/Makefile.SH
+   $spitshell >>Makefile <<!GROK!THIS!
+ 
+ Makefile: $osname/Makefile.SH
+ 
+ !GROK!THIS!
+ else
+   echo "Could not find $osname/Makefile.SH! Skipping target \$(perllib) in Makefile!"
+ fi
+ ;;
  *)
  $spitshell >>Makefile <<'!NO!SUBS!'
  	rm -f $(perllib)
! 	$(AR) rcu $(perllib) perl$(O) $(obj)
  	@$(ranlib) $(perllib)
  !NO!SUBS!
  ;;
***************
*** 245,254 ****
  # checks as well as the special code to validate that the script in question
  # has been invoked correctly.
  
! suidperl: $& sperl.o perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o suidperl perlmain.o sperl.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! sperl.o: perl.c perly.h patchlevel.h $(h)
  	$(RMS) sperl.c
  	$(LNS) perl.c sperl.c
  	$(CCCMD) -DIAMSUID sperl.c
--- 287,296 ----
  # checks as well as the special code to validate that the script in question
  # has been invoked correctly.
  
! suidperl: $& sperl$(O) perlmain$(O) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o suidperl perlmain$(O) sperl$(O) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! sperl$(O): perl.c perly.h patchlevel.h $(h)
  	$(RMS) sperl.c
  	$(LNS) perl.c sperl.c
  	$(CCCMD) -DIAMSUID sperl.c
***************
*** 258,264 ****
  #	test -d lib/auto || mkdir lib/auto
  #
  preplibrary: miniperl lib/Config.pm
! 	@./makedir lib/auto
  	@echo "	AutoSplitting perl library"
  	@./miniperl -Ilib -e 'use AutoSplit; \
  		autosplit_lib_modules(@ARGV)' lib/*.pm lib/*/*.pm
--- 300,306 ----
  #	test -d lib/auto || mkdir lib/auto
  #
  preplibrary: miniperl lib/Config.pm
! 	@sh ./makedir lib/auto
  	@echo "	AutoSplitting perl library"
  	@./miniperl -Ilib -e 'use AutoSplit; \
  		autosplit_lib_modules(@ARGV)' lib/*.pm lib/*/*.pm
***************
*** 339,346 ****
  	@sh ext/util/make_ext static $@ LIBPERL_A=$(perllib)
  
  clean:
! 	rm -f *.o *.a all perlmain.c
  	rm -f perl.exp ext.libs
  	-cd x2p; $(MAKE) clean
  	-cd pod; $(MAKE) clean
  	-@for x in $(DYNALOADER) $(dynamic_ext) $(static_ext) ; do \
--- 381,389 ----
  	@sh ext/util/make_ext static $@ LIBPERL_A=$(perllib)
  
  clean:
! 	rm -f *$(O) *$(A) all perlmain.c
  	rm -f perl.exp ext.libs
+ 	-rm perl.export perl.dll perl.libexp perl.map perl.def
  	-cd x2p; $(MAKE) clean
  	-cd pod; $(MAKE) clean
  	-@for x in $(DYNALOADER) $(dynamic_ext) $(static_ext) ; do \
***************
*** 356,362 ****
  	done
  	rm -f *.orig */*.orig *~ */*~ core t/core t/c t/perl
  	rm -rf $(addedbyconf)
! 	rm -f makefile makefile.old
  	rm -f $(private)
  	rm -rf lib/auto
  	rm -f lib/.exists
--- 399,405 ----
  	done
  	rm -f *.orig */*.orig *~ */*~ core t/core t/c t/perl
  	rm -rf $(addedbyconf)
! 	rm -f $(firstmakefile) makefile.old
  	rm -f $(private)
  	rm -rf lib/auto
  	rm -f lib/.exists
***************
*** 377,383 ****
  lint: perly.c $(c)
  	lint $(lintflags) $(defs) perly.c $(c) > perl.fuzz
  
! makefile:	Makefile
  	$(MAKE) depend
  
  config.h: config.sh
--- 420,426 ----
  lint: perly.c $(c)
  	lint $(lintflags) $(defs) perly.c $(c) > perl.fuzz
  
! $(firstmakefile):	Makefile
  	$(MAKE) depend
  
  config.h: config.sh
***************
*** 385,401 ****
  
  # When done, touch perlmain.c so that it doesn't get remade each time.
  depend: makedepend
! 	./makedepend
  	- test -s perlmain.c && touch perlmain.c
  	cd x2p; $(MAKE) depend
  
  test: miniperl perl preplibrary $(dynamic_ext)
  	- cd t && chmod +x TEST */*.t
! 	- cd t && (rm -f perl; $(LNS) ../perl perl) && ./perl TEST </dev/tty
  
  minitest: miniperl
  	- cd t && chmod +x TEST */*.t
! 	- cd t && (rm -f perl; $(LNS) ../miniperl perl) \
  		&& ./perl TEST base/*.t comp/*.t cmd/*.t io/*.t op/*.t </dev/tty
  
  clist:	$(c)
--- 428,444 ----
  
  # When done, touch perlmain.c so that it doesn't get remade each time.
  depend: makedepend
! 	sh ./makedepend
  	- test -s perlmain.c && touch perlmain.c
  	cd x2p; $(MAKE) depend
  
  test: miniperl perl preplibrary $(dynamic_ext)
  	- cd t && chmod +x TEST */*.t
! 	- cd t && (rm -f perl$(exe_ext); $(LNS) ../perl$(exe_ext) perl$(exe_ext)) && ./perl TEST </dev/tty
  
  minitest: miniperl
  	- cd t && chmod +x TEST */*.t
! 	- cd t && (rm -f perl$(exe_ext); $(LNS) ../miniperl$(exe_ext) perl$(exe_ext)) \
  		&& ./perl TEST base/*.t comp/*.t cmd/*.t io/*.t op/*.t </dev/tty
  
  clist:	$(c)
***************
*** 415,421 ****
  case `pwd` in
  *SH)
      $rm -f ../Makefile
!     ln Makefile ../Makefile
      ;;
  esac
! rm -f makefile
--- 458,464 ----
  case `pwd` in
  *SH)
      $rm -f ../Makefile
!     $ln Makefile ../Makefile
      ;;
  esac
! rm -f $firstmakefile
