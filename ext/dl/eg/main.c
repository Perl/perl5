#include <dlfcn.h>
#include <stdio.h>

main(argc, argv, arge)
int argc;
char **argv;
char **arge;
{
    void	*obj;
    void	(*proc)();
    void	*obj1;
    void	(*proc1)();

    if (!(obj = dlopen("test", 1)))
	fprintf(stderr, "%s\n", dlerror());
    if (!(obj1 = dlopen("test1", 1)))
	fprintf(stderr, "%s\n", dlerror());
    proc = (void (*)())dlsym(obj, "test");
    proc1 = (void (*)())dlsym(obj1, "test1");
    proc();
    proc1();
    dlclose(obj);
}

void print()
{
    printf("got here!\n");
}
