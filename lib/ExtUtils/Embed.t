#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
use Config;
use ExtUtils::Embed;

open(my $fh,">embed_test.c") || die "Cannot open embed_test.c:$!";
print $fh <DATA>;
close($fh);

$| = 1;
print "1..9\n";
my @cmd = ($Config{'cc'},-o => 'embed_test',"-I$INC[0]/..",
           ccopts(),
           'embed_test.c',"-L$INC[0]/..",'-lperl',ldopts()
           );
#print "#@cmd\n";
print "not " if system(join(' ',@cmd));
print "ok 1\n";
print "not " if system("embed_test");
print "ok 9\n";
unlink("embed_test","embed_test.c");

#gcc -g -I.. -L../ -o perl_test perl_test.c -lperl `../perl -I../lib -MExtUtils::Embed -I../ -e ccopts -e ldopts`

__END__

/* perl_test.c */

#include <EXTERN.h>
#include <perl.h>

#define my_puts(a) if(puts(a) < 0) exit(666)

char *cmds[] = { "perl","-e", "print qq[ok 5\\n]", NULL };

int main(int argc, char **argv, char **env)
{
    PerlInterpreter *my_perl = perl_alloc();

    my_puts("ok 2");

    perl_construct(my_perl);

    my_puts("ok 3");

    perl_parse(my_perl, NULL, (sizeof(cmds)/sizeof(char *))-1, cmds, env);

    my_puts("ok 4");

    fflush(stdout);

    perl_run(my_perl);

    my_puts("ok 6");

    perl_destruct(my_perl);

    my_puts("ok 7");

    perl_free(my_perl);

    my_puts("ok 8");

    return 0;
}




