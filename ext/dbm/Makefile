all: NDBM_File.c ODBM_File.c GDBM_File.c SDBM_File.c

NDBM_File.c: NDBM_File.xs
	../xsubpp NDBM_File.xs >NDBM_File.c

SDBM_File.c: SDBM_File.xs
	../xsubpp SDBM_File.xs >SDBM_File.c

SDBM_File.o: SDBM_File.c
	cc -g -I../.. -pic -c SDBM_File.c

SDBM_File.so: SDBM_File.o sdbm/libsdbm.a
	ld -o SDBM_File.so SDBM_File.o sdbm/libsdbm.a

ODBM_File.c: ODBM_File.xs
	../xsubpp ODBM_File.xs >ODBM_File.c

GDBM_File.c: GDBM_File.xs
	../xsubpp GDBM_File.xs >GDBM_File.c

