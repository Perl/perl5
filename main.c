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

    boot_DynamicLoader();

#ifdef HAS_DB
    newXSUB("DB_File::bootstrap",   0, boot_DB_File,   file);
#endif
#ifdef HAS_NDBM
    newXSUB("NDBM_File::bootstrap", 0, boot_NDBM_File, file);
#endif
#ifdef HAS_GDBM
    newXSUB("GDBM_File::bootstrap", 0, boot_GDBM_File, file);
#endif
#ifdef HAS_SDBM
/*    newXSUB("SDBM_File::bootstrap", 0, boot_SDBM_File, file); */
#endif
#ifdef HAS_ODBM
    newXSUB("ODBM_File::bootstrap", 0, boot_ODBM_File, file);
#endif
#ifdef HAS_DBZ
    newXSUB("DBZ_File::bootstrap",  0, boot_DBZ_File,  file);
#endif
    newXSUB("POSIX::bootstrap",  0, boot_POSIX,  file);
}
