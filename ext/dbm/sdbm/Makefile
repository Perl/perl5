#
# This Makefile is for the library part of sdbm.  For the
# Full package, see makefile.sdbm.
# 
# Makefile for public domain ndbm-clone: sdbm
# DUFF: use duff's device (loop unroll) in parts of the code
#
#
CC = cc
ranlib = /usr/bin/ranlib
TOP = ../../..
LDFLAGS = 
CLDFLAGS = 
SMALL = 
LARGE =  

# To use an alternate make, set  in config.sh.
MAKE = make

SHELL = /bin/sh
CCCMD = `sh $(shellflags) $(TOP)/cflags $@`

.c.o:
	$(CCCMD) -I$(TOP) -DSDBM -DDUFF $*.c

LIBOBJS = sdbm.o pair.o hash.o
LIBSRCS = sdbm.c pair.c hash.c
HDRS = tune.h sdbm.h pair.h $(TOP)/config.h

libsdbm.a: $(LIBOBJS)
	ar cr libsdbm.a $(LIBOBJS)
	$(ranlib) libsdbm.a

$(LIBOBJS): $(HDRS)

lint:
	lint -abchx $(LIBSRCS)

clean:
	rm -f *.o *.a mon.out core

realclean: 	clean
	rm -f dbu libsdbm.a dbd dba dbe x-dbu *.dir *.pag
	rm -f makefile Makefile

purge:	realclean

