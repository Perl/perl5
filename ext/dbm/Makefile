all: NDBM_File.c ODBM_File.c GDBM_File.c SDBM_File.c

NDBM_File.c: NDBM_File.xs
	../xsubpp ../typemap NDBM_File.xs >NDBM_File.c

SDBM_File.c: SDBM_File.xs
	../xsubpp ../typemap SDBM_File.xs >SDBM_File.c

ODBM_File.c: ODBM_File.xs
	../xsubpp ../typemap ODBM_File.xs >ODBM_File.c

GDBM_File.c: GDBM_File.xs
	../xsubpp ../typemap GDBM_File.xs >GDBM_File.c

