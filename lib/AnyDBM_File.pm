package AnyDBM_File;

@ISA = qw(NDBM_File DB_File GDBM_File SDBM_File ODBM_File) unless @ISA;

eval { require NDBM_File } ||
eval { require DB_File } ||
eval { require GDBM_File } ||
eval { require SDBM_File } ||
eval { require ODBM_File };
