#include "INTERN.h"
#include "perl.h"

main(argc, argv, env)
int argc;
char **argv;
char **env;
{
    int exitstatus;
    Interpreter *my_perl;

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
