WHAT = PerlInterpreter
JAVA_HOME = /usr/local/java
JPL_HOME = /usr/local/jpl
ARCHNAME = sun4-solaris
PERLARCHDIR = /usr/local/lib/perl5/sun4-solaris/5.00404
CC = gcc
FLAGS = -fPIC   -R /usr/local/lib/perl5/sun4-solaris/5.00404/CORE -G -L/usr/local/lib 
INCL  = -I$(PERLARCHDIR)/CORE \
	-I$(JAVA_HOME)/include \
	-I$(JAVA_HOME)/include/solaris \
	-I$(JAVA_HOME)/include/genunix
LIBS = -lc -lm -ldl

.SUFFIXES: .java .class

.java.class:
	javac $*.java

.class.h:
	javah -jni $*

all: PerlInterpreter.class libPerlInterpreter.so

PerlInterpreter.class: PerlInterpreter.java

PerlInterpreter.h: PerlInterpreter.class

libPerlInterpreter.so: PerlInterpreter.c PerlInterpreter.h
	$(CC) $(FLAGS) $(INCL) PerlInterpreter.c \
	$(PERLARCHDIR)/auto/DynaLoader/DynaLoader.a \
	$(LIBS) \
	-o libPerlInterpreter.so

test:

install: all
	mkdir -p $(JPL_HOME)/lib/$(ARCHNAME)
	cp libPerlInterpreter.so $(JPL_HOME)/lib/$(ARCHNAME)
	cp $(WHAT).class $(JPL_HOME)/lib

clean:
	rm -f libPerlInterpreter.so
	rm -f PerlInterpreter.class
