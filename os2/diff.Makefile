*** Makefile.SH.orig	Mon Nov 20 12:56:12 1995
--- Makefile.SH	Fri Dec 08 00:02:46 1995
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
  
--- 31,44 ----
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
--- 54,60 ----
  static_ai_list=' '
  for f in $static_ext; do
  	base=`echo "$f" | sed 's/.*\///'`
! 	static_list="$static_list lib/auto/$f/$base\$(LIB_EXT)"
  	if test -f ext/$f/AutoInit.c; then
  	    static_ai_list="$static_ai_list ext/$f/AutoInit.c"
  	fi
***************
*** 115,122 ****
  static_ext = $static_list
  ext = \$(dynamic_ext) \$(static_ext)
  static_ext_autoinit = $static_ai_list
! DYNALOADER = lib/auto/DynaLoader/DynaLoader.a
! 
  
  libs = $libs $cryptlib
  
--- 116,122 ----
  static_ext = $static_list
  ext = \$(dynamic_ext) \$(static_ext)
  static_ext_autoinit = $static_ai_list
! DYNALOADER = lib/auto/DynaLoader/DynaLoader\$(LIB_EXT)
  
  libs = $libs $cryptlib
  
***************
*** 140,145 ****
--- 140,147 ----
  # Any special object files needed by this architecture, e.g. os2/os2.obj
  ARCHOBJS = $archobjs
  
+ .SUFFIXES: .c \$(OBJ_EXT)
+ 
  !GROK!THIS!
  
  ## In the following dollars and backticks do not need the extra backslash.
***************
*** 180,190 ****
  
  c = $(c1) $(c2) $(c3) miniperlmain.c perlmain.c
  
! obj1 = $(mallocobj) gv.o toke.o perly.o op.o regcomp.o dump.o util.o mg.o
! obj2 = hv.o av.o run.o pp_hot.o sv.o pp.o scope.o pp_ctl.o pp_sys.o
! obj3 = doop.o doio.o regexec.o taint.o deb.o globals.o
! 
! 
  obj = $(obj1) $(obj2) $(obj3) $(ARCHOBJS)
  
  # Once perl has been Configure'd and built ok you build different
--- 182,191 ----
  
  c = $(c1) $(c2) $(c3) miniperlmain.c perlmain.c
  
! obj1 = $(mallocobj) gv$(OBJ_EXT) toke$(OBJ_EXT) perly$(OBJ_EXT) op$(OBJ_EXT) regcomp$(OBJ_EXT) dump$(OBJ_EXT) util$(OBJ_EXT) mg$(OBJ_EXT)
! obj2 = hv$(OBJ_EXT) av$(OBJ_EXT) run$(OBJ_EXT) pp_hot$(OBJ_EXT) sv$(OBJ_EXT) pp$(OBJ_EXT) scope$(OBJ_EXT) pp_ctl$(OBJ_EXT) pp_sys$(OBJ_EXT)
! obj3 = doop$(OBJ_EXT) doio$(OBJ_EXT) regexec$(OBJ_EXT) taint$(OBJ_EXT) deb$(OBJ_EXT) globals$(OBJ_EXT)
!   
  obj = $(obj1) $(obj2) $(obj3) $(ARCHOBJS)
  
  # Once perl has been Configure'd and built ok you build different
***************
*** 203,209 ****
  # grrr
  SHELL = /bin/sh
  
! .c.o:
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  all: makefile miniperl $(private) $(plextract) $(public) $(dynamic_ext)
--- 204,210 ----
  # grrr
  SHELL = /bin/sh
  
! .c$(OBJ_EXT):
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  all: makefile miniperl $(private) $(plextract) $(public) $(dynamic_ext)
***************
*** 220,236 ****
  # The $& notation tells Sequent machines that it can do a parallel make,
  # and is harmless otherwise.
  
! miniperl: $& miniperlmain.o $(perllib)
! 	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain.o $(perllib) $(libs)
  
! miniperlmain.o: miniperlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  perlmain.c: miniperlmain.c config.sh makefile $(static_ext_autoinit)
  	sh writemain $(DYNALOADER) $(static_ext) > tmp
  	sh mv-if-diff tmp perlmain.c
  
! perlmain.o: perlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  # The file ext.libs is a list of libraries that must be linked in
--- 221,237 ----
  # The $& notation tells Sequent machines that it can do a parallel make,
  # and is harmless otherwise.
  
! miniperl: $& miniperlmain$(OBJ_EXT) $(perllib)
! 	$(CC) $(LARGE) $(CLDFLAGS) -o miniperl miniperlmain$(OBJ_EXT) $(perllib) $(libs)
  
! miniperlmain$(OBJ_EXT): miniperlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  perlmain.c: miniperlmain.c config.sh makefile $(static_ext_autoinit)
  	sh writemain $(DYNALOADER) $(static_ext) > tmp
  	sh mv-if-diff tmp perlmain.c
  
! perlmain$(OBJ_EXT): perlmain.c
  	$(CCCMD) $(PLDLFLAGS) $*.c
  
  # The file ext.libs is a list of libraries that must be linked in
***************
*** 239,266 ****
  ext.libs: $(static_ext)
  	-@test -f ext.libs || touch ext.libs
  
! perl: $& perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(SHRPENV) $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o perl perlmain.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! pureperl: $& perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	purify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o pureperl perlmain.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! quantperl: $& perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	quantify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o quantperl perlmain.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
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
! 	$(AR) rcu $(perllib) perl.o $(obj)
  	@$(ranlib) $(perllib)
  !NO!SUBS!
  ;;
--- 240,279 ----
  ext.libs: $(static_ext)
  	-@test -f ext.libs || touch ext.libs
  
! perl: $& perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(SHRPENV) $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o perl perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! pureperl: $& perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	purify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o pureperl perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! quantperl: $& perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	quantify $(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o quantperl perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! $(perllib): $& perl$(OBJ_EXT) $(obj)
  !NO!SUBS!
  
  case "$d_shrplib" in
  *define*)
  $spitshell >>Makefile <<'!NO!SUBS!'
! 	$(LD) $(LDDLFLAGS) -o $@ perl$(OBJ_EXT) $(obj)
  !NO!SUBS!
  ;;
+ custom)
+ if test -r $osname/Makefile.SHs ; then 
+   . $osname/Makefile.SHs
+   $spitshell >>Makefile <<!GROK!THIS!
+ 
+ Makefile: $osname/Makefile.SHs
+ 
+ !GROK!THIS!
+ else
+   echo "Could not find $osname/Makefile.SH! Skipping target \$(perllib) in Makefile!"
+ fi
+ ;;
  *)
  $spitshell >>Makefile <<'!NO!SUBS!'
  	rm -f $(perllib)
! 	$(AR) rcu $(perllib) perl$(OBJ_EXT) $(obj)
  	@$(ranlib) $(perllib)
  !NO!SUBS!
  ;;
***************
*** 273,282 ****
  # checks as well as the special code to validate that the script in question
  # has been invoked correctly.
  
! suidperl: $& sperl.o perlmain.o $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o suidperl perlmain.o sperl.o $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! sperl.o: perl.c perly.h patchlevel.h $(h)
  	$(RMS) sperl.c
  	$(LNS) perl.c sperl.c
  	$(CCCMD) -DIAMSUID sperl.c
--- 286,295 ----
  # checks as well as the special code to validate that the script in question
  # has been invoked correctly.
  
! suidperl: $& sperl$(OBJ_EXT) perlmain$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) ext.libs
! 	$(CC) $(LARGE) $(CLDFLAGS) $(CCDLFLAGS) -o suidperl perlmain$(OBJ_EXT) sperl$(OBJ_EXT) $(perllib) $(DYNALOADER) $(static_ext) `cat ext.libs` $(libs)
  
! sperl$(OBJ_EXT): perl.c perly.h patchlevel.h $(h)
  	$(RMS) sperl.c
  	$(LNS) perl.c sperl.c
  	$(CCCMD) -DIAMSUID sperl.c
***************
*** 286,292 ****
  #	test -d lib/auto || mkdir lib/auto
  #
  preplibrary: miniperl lib/Config.pm $(plextract)
! 	@./makedir lib/auto
  	@echo "	AutoSplitting perl library"
  	@./miniperl -Ilib -e 'use AutoSplit; \
  		autosplit_lib_modules(@ARGV)' lib/*.pm lib/*/*.pm
--- 299,305 ----
  #	test -d lib/auto || mkdir lib/auto
  #
  preplibrary: miniperl lib/Config.pm $(plextract)
! 	@sh ./makedir lib/auto
  	@echo "	AutoSplitting perl library"
  	@./miniperl -Ilib -e 'use AutoSplit; \
  		autosplit_lib_modules(@ARGV)' lib/*.pm lib/*/*.pm
***************
*** 304,317 ****
  
  install: all install.perl install.man
  
! install.perl:	all
  	./perl installperl
  
! install.man:	all
  	./perl installman
  
  # Not implemented yet.
! #install.html:	all
  #	./perl installhtml
  
  # I now supply perly.c with the kits, so the following section is
--- 317,330 ----
  
  install: all install.perl install.man
  
! install.perl:	all installperl
  	./perl installperl
  
! install.man:	all installman
  	./perl installman
  
  # Not implemented yet.
! #install.html:	all installhtml
  #	./perl installhtml
  
  # I now supply perly.c with the kits, so the following section is
***************
*** 371,378 ****
  	@sh ext/util/make_ext static $@ LIBPERL_A=$(perllib)
  
  clean:
! 	rm -f *.o *.a all perlmain.c
  	rm -f perl.exp ext.libs
  	-cd x2p; $(MAKE) clean
  	-cd pod; $(MAKE) clean
  	-@for x in $(DYNALOADER) $(dynamic_ext) $(static_ext) ; do \
--- 384,392 ----
  	@sh ext/util/make_ext static $@ LIBPERL_A=$(perllib)
  
  clean:
! 	rm -f *$(OBJ_EXT) *$(LIB_EXT) all perlmain.c
  	rm -f perl.exp ext.libs
+ 	-rm perl.export perl.dll perl.libexp perl.map perl.def
  	-cd x2p; $(MAKE) clean
  	-cd pod; $(MAKE) clean
  	-@for x in $(DYNALOADER) $(dynamic_ext) $(static_ext) ; do \
***************
*** 389,395 ****
  	done
  	rm -f *.orig */*.orig *~ */*~ core t/core t/c t/perl
  	rm -rf $(addedbyconf)
! 	rm -f makefile makefile.old
  	rm -f $(private)
  	rm -rf lib/auto
  	rm -f lib/.exists
--- 403,409 ----
  	done
  	rm -f *.orig */*.orig *~ */*~ core t/core t/c t/perl
  	rm -rf $(addedbyconf)
! 	rm -f $(FIRSTMAKEFILE) $(FIRSTMAKEFILE).old
  	rm -f $(private)
  	rm -rf lib/auto
  	rm -f lib/.exists
***************
*** 410,434 ****
  lint: perly.c $(c)
  	lint $(lintflags) $(defs) perly.c $(c) > perl.fuzz
  
! makefile:	Makefile
! 	$(MAKE) depend
  
  config.h: config.sh
  	/bin/sh config_h.SH
  
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
--- 424,456 ----
  lint: perly.c $(c)
  	lint $(lintflags) $(defs) perly.c $(c) > perl.fuzz
  
! # Need to unset during recursion to go out of loop
! 
! MAKEDEPEND = makedepend
! 
! $(FIRSTMAKEFILE):	Makefile $(MAKEDEPEND)
! 	$(MAKE) depend MAKEDEPEND=
  
  config.h: config.sh
  	/bin/sh config_h.SH
  
  # When done, touch perlmain.c so that it doesn't get remade each time.
  depend: makedepend
! 	sh ./makedepend
  	- test -s perlmain.c && touch perlmain.c
  	cd x2p; $(MAKE) depend
  
+ # Cannot postpone this until $firstmakefile is ready ;-)
+ makedepend: makedepend.SH config.sh
+ 	sh ./makedepend.SH
+ 
  test: miniperl perl preplibrary $(dynamic_ext)
  	- cd t && chmod +x TEST */*.t
! 	- cd t && (rm -f perl$(EXE_EXT); $(LNS) ../perl$(EXE_EXT) perl$(EXE_EXT)) && ./perl TEST </dev/tty
  
  minitest: miniperl
  	- cd t && chmod +x TEST */*.t
! 	- cd t && (rm -f perl$(EXE_EXT); $(LNS) ../miniperl$(EXE_EXT) perl$(EXE_EXT)) \
  		&& ./perl TEST base/*.t comp/*.t cmd/*.t io/*.t op/*.t </dev/tty
  
  clist:	$(c)
***************
*** 451,457 ****
  case `pwd` in
  *SH)
      $rm -f ../Makefile
!     ln Makefile ../Makefile
      ;;
  esac
! rm -f makefile
--- 473,479 ----
  case `pwd` in
  *SH)
      $rm -f ../Makefile
!     $ln Makefile ../Makefile
      ;;
  esac
! $rm -f $firstmakefile
