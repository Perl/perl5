/* Say NO to CPP! Hallelujah! */
#ifdef __GNUC__
#define __declspec(foo) 
#endif

__declspec(dllimport) int RunPerl(int argc, char **argv, char **env, void *ios);

int
main(int argc, char **argv, char **env)
{
    return RunPerl(argc, argv, env, (void*)0);
}
