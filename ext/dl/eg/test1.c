#include <dlfcn.h>

test1()
{
    void	*obj;
    void	(*proc)();

    obj = dlopen("test", 1);
    proc = (void (*)())dlsym(obj, "test");
    proc();
}
