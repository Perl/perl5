/*
 * dba	dbm analysis/recovery
 */

#include <stdio.h>
#include <sys/file.h>
#include "EXTERN.h"
#include "sdbm.h"

char *progname;
extern void oops();

int
main(int argc, char **argv)
{
        int n;
        char *p;
        char *name;
        int pagf;

        progname = argv[0];

        if (p = argv[1]) {
                name = (char *) malloc((n = strlen(p)) + 5);
                if (!name)
                    oops("cannot get memory");

                strcpy(name, p);
                strcpy(name + n, ".pag");

                if ((pagf = open(name, O_RDONLY)) < 0)
                        oops("cannot open %s.", name);

                sdump(pagf);
        }
        else
                oops("usage: %s dbname", progname);

        return 0;
}

void
sdump(int pagf)
{
        int b;
        int n = 0;
        int t = 0;
        int o = 0;
        int e;
        char pag[PBLKSIZ];

        while ((b = read(pagf, pag, PBLKSIZ)) > 0) {
                printf("#%d: ", n);
                if (!okpage(pag))
                        printf("bad\n");
                else {
                        printf("ok. ");
                        if (!(e = pagestat(pag)))
                            o++;
                        else
                            t += e;
                }
                n++;
        }

        if (b == 0)
                printf("%d pages (%d holes):  %d entries\n", n, o, t);
        else
                oops("read failed: block %d", n);
}

int
pagestat(char *pag)
{
        int n;
        int free;
        short *ino = (short *) pag;

        if (!(n = ino[0]))
                printf("no entries.\n");
        else {
                free = ino[n] - (n + 1) * sizeof(short);
                printf("%3d entries %2d%% used free %d.\n",
                       n / 2, ((PBLKSIZ - free) * 100) / PBLKSIZ, free);
        }
        return n / 2;
}
