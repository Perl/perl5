: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.

case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

if test -f config.sh; then TOP=.;
elif test -f ../config.sh; then TOP=..;
elif test -f ../../config.sh; then TOP=../..;
elif test -f ../../../config.sh; then TOP=../../..;
elif test -f ../../../../config.sh; then TOP=../../../..;
else
	echo "Can't find config.sh."; exit 1
fi

: Find absolute path name for TOP.  This is needed when we cd to TOP
: to run perl on autosplit.
oldpwd=`pwd`; cd $TOP; ABSTOP=`pwd`; cd $oldpwd

case $CONFIG in
'')
	. $TOP/config.sh
	;;
esac

: Find out directory name.  This is also the extension name.
ext=`pwd | $sed -e 's@.*/@@'`

: This extension might have its own typemap
if test -f typemap; then
	exttypemap='typemap'
else
	exttypemap=''
fi

: This extension might need additional libraries.
potential_libs=" "
. $TOP/ext/util/extliblist

: This extension might need bootstrap support
if test -f ${ext}_BS; then
	bootdep=${ext}_BS
else
	bootdep=''
fi

case "$dlsrc" in
dl_aix*)
    echo "#!" > $ext.exp
    echo "boot_$ext" >> $ext.exp
    ;;
esac

echo "Extracting ext/$ext/Makefile (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >Makefile << !GROK!THIS!
#
# This Makefile is for the $ext extension to perl.
# 
CC = $cc
RANLIB = $ranlib
TOP = $TOP
ABSTOP = $ABSTOP
LDFLAGS = $ldflags
CLDFLAGS = $ldflags
SMALL = $small
LARGE = $large $split

# To use an alternate make, set \$altmake in config.sh.
MAKE = ${altmake-make}

EXT = $ext

# $ext might have its own typemap
EXTTYPEMAP = $exttypemap

# $ext might have its own bootstrap support
BOOTDEP  = $bootdep
BOOTSTRAP  = $ext.bs

# The following are used to build and install shared libraries for
# dynamic loading.
LDDLFLAGS = $lddlflags
CCDLFLAGS = $ccdlflags
CCCDLFLAGS = $cccdlflags
SO = $so
DLEXT = $dlext

# $ext might need to be linked with some extra libraries.
# EXTRALIBS =  full list of libraries needed for static linking.
#		Only those libraries that actually exist are included.
# DYNLOADLIBS = list of those libraries that are needed but can be
#		linked in dynamically on this platform.  On SunOS, for
#		example, this would be .so* libraries, but not archive
#		libraries.  The bootstrap file is installed only if
#		this list is not empty.
# STATLOADLIBS = list of those libraries which must be statically
#		linked into the shared library.  On SunOS 4.1.3, 
#		for example,  I have only an archive version of
#		-lm, and it must be linked in statically.
EXTRALIBS = $extralibs
DYNALOADLIBS  = $dynaloadlibs
STATLOADLIBS = $statloadlibs

!GROK!THIS!

$spitshell >>Makefile <<'!NO!SUBS!'

# Where to put things:
AUTO = $(TOP)/lib/auto
INSTALLBOOT = $(AUTO)/$(EXT)/$(EXT).bs
INSTALLDYNAMIC = $(AUTO)/$(EXT)/$(EXT).$(DLEXT)
INSTALLSTATIC = $(EXT).a
INSTALLPM = $(TOP)/lib/$(EXT).pm

PERL = $(ABSTOP)/miniperl
XSUBPP = $(TOP)/ext/xsubpp
SHELL = /bin/sh
CCCMD = `sh $(shellflags) $(TOP)/cflags $@`

.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(TOP) $*.c

all:	dynamic
# Phony target to force checking subdirectories.
FORCE:

config:

# Target for Dynamic Loading:
dynamic:	$(INSTALLDYNAMIC) $(INSTALLPM) $(INSTALLBOOT)

$(INSTALLDYNAMIC): $(EXT).o sdbm/libsdbm.a
	@test -d $(AUTO) || mkdir $(AUTO)
	@test -d $(AUTO)/$(EXT) || mkdir $(AUTO)/$(EXT)
	ld $(LDDLFLAGS) -o $@ $(EXT).o sdbm/libsdbm.a $(STATLOADLIBS)

$(BOOTSTRAP):	Makefile $(BOOTDEP)
	$(PERL) -I$(TOP)/lib $(TOP)/ext/util/mkbootstrap $(DYNALOADLIBS)
	touch $(BOOTSTRAP)

$(INSTALLBOOT):	$(BOOTSTRAP)
	@test ! -s $(BOOTSTRAP) || cp $(BOOTSTRAP) $@

# Target for Static Loading:
static: $(INSTALLSTATIC) $(INSTALLPM)

$(INSTALLSTATIC):	$(EXT).o sdbm/libsdbm.a
	cp sdbm/libsdbm.a $@
	ar r $@ $(EXT).o
	$(RANLIB) $@
	echo $(EXTRALIBS) >> $(TOP)/ext.libs

$(EXT).c:	$(EXT).xs $(XSUBPP) $(TOP)/ext/typemap $(EXTTYPEMAP) $(TOP)/cflags Makefile
	$(PERL) $(XSUBPP) $(EXT).xs >tmp
	mv tmp $@

sdbm/libsdbm.a:	FORCE
	@cd sdbm;  \
	if test ! -f Makefile ; then \
	test -f Makefile.SH && sh Makefile.SH ; \
	fi ; 	$(MAKE)

$(INSTALLPM):	$(EXT).pm
	rm -f $@
	cp $(EXT).pm $@
	cd $(TOP); $(PERL) autosplit $(EXT)

clean:
	-cd sdbm; $(MAKE) clean
	rm -f *.o *.a mon.out core $(EXT).c so_locations $(BOOTSTRAP) $(EXT).exp

realclean: 	clean
	-cd sdbm; $(MAKE) realclean
	rm -f makefile Makefile
	rm -f $(INSTALLPM) $(INSTALLDYNAMIC) $(INSTALLSTATIC) $(INSTALLBOOT)
	rm -rf $(AUTO)/$(EXT)

purge:	realclean

$(EXT).o :	$(TOP)/EXTERN.h
$(EXT).o :	$(TOP)/perl.h
$(EXT).o :	$(TOP)/embed.h
$(EXT).o :	$(TOP)/config.h
$(EXT).o :	$(TOP)/unixish.h
$(EXT).o :	$(TOP)/handy.h
$(EXT).o :	$(TOP)/regexp.h
$(EXT).o :	$(TOP)/sv.h
$(EXT).o :	$(TOP)/util.h
$(EXT).o :	$(TOP)/form.h
$(EXT).o :	$(TOP)/gv.h
$(EXT).o :	$(TOP)/cv.h
$(EXT).o :	$(TOP)/opcode.h
$(EXT).o :	$(TOP)/op.h
$(EXT).o :	$(TOP)/cop.h
$(EXT).o :	$(TOP)/av.h
$(EXT).o :	$(TOP)/hv.h
$(EXT).o :	$(TOP)/mg.h
$(EXT).o :	$(TOP)/scope.h
$(EXT).o :	$(TOP)/pp.h
$(EXT).o :	$(TOP)/proto.h
$(EXT).o :	$(TOP)/XSUB.h 

Makefile:	Makefile.SH $(TOP)/config.sh ; /bin/sh Makefile.SH
$(TOP)/config.h:	$(TOP)/config.sh; cd $(TOP); /bin/sh config_h.SH
$(TOP)/embed.h:	$(TOP)/config.sh; cd $(TOP); /bin/sh embed_h.SH
$(TOP)/cflags:	$(TOP)/config.sh; cd $(TOP); /bin/sh cflags.SH

!NO!SUBS!
chmod 644 Makefile
$eunicefix Makefile

