#include "INTERN.h"
#include "perl.h"

main(argc, argv, env)
int argc;
char **argv;
char **env;
{
    int exitstatus;
    PerlInterpreter *my_perl;

    my_perl = perl_alloc();
    if (!my_perl)
	exit(1);
    perl_construct( my_perl );

    exitstatus = perl_parse( my_perl, argc, argv, env );
    if (exitstatus)
	exit( exitstatus );

    exitstatus = perl_run( my_perl );

    perl_destruct( my_perl );
    perl_free( my_perl );

    exit( exitstatus );
}

/* Register any extra external extensions */

void
perl_init_ext()
{
    char *file = __FILE__;

#ifdef HAS_DB
    newXSUB("DB_File::init",   0, init_DB_File,   file);
#endif
#ifdef HAS_NDBM
    newXSUB("NDBM_File::init", 0, init_NDBM_File, file);
#endif
#ifdef HAS_GDBM
    newXSUB("GDBM_File::init", 0, init_GDBM_File, file);
#endif
#ifdef HAS_SDBM
    newXSUB("SDBM_File::init", 0, init_SDBM_File, file);
#endif
#ifdef HAS_ODBM
    newXSUB("ODBM_File::init", 0, init_ODBM_File, file);
#endif
#ifdef HAS_DBZ
    newXSUB("DBZ_File::init",  0, init_DBZ_File,  file);
#endif
}
