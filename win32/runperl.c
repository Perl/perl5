/* Say NO to CPP! Hallelujah! */

__declspec(dllimport) int RunPerl(int argc, char **argv, char **env, void *ios);

int
main(int argc, char **argv, char **env)
{
    return RunPerl(argc, argv, env, (void*)0);
}
