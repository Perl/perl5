#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
use Config;
use ExtUtils::Embed;
use File::Spec;

open(my $fh,">embed_test.c") || die "Cannot open embed_test.c:$!";
print $fh <DATA>;
close($fh);

$| = 1;
print "1..9\n";
my $cc = $Config{'cc'};
my $cl  = ($^O eq 'MSWin32' && $cc eq 'cl');
my $exe = 'embed_test' . $Config{'exe_ext'};
my $inc = File::Spec->catdir($INC[0],"..");
my $lib = File::Spec->catdir($INC[0],"..");
my @cmd;
if ($cl) {
    push(@cmd,$cc,"-Fe$exe");
}
else {
    push(@cmd,$cc,'-o' => $exe);
}
push(@cmd,"-I$inc",ccopts(),'embed_test.c');
if ($^O eq 'MSWin32') {
    $inc = File::Spec->catdir($inc,'win32');
    push(@cmd,"-I$inc");
    $inc = File::Spec->catdir($inc,'include');
    push(@cmd,"-I$inc");
    if ($cc eq 'cl') {
	push(@cmd,'-link',"-libpath:$lib",$Config{'libperl'},$Config{'libc'});
    }
    else {
	push(@cmd,"-L$lib",File::Spec->catfile($lib,$Config{'libperl'}),$Config{'libc'});
    }
}
else {
    push(@cmd,"-L$lib",'-lperl');
}
{
    local $SIG{__WARN__} = sub {
	warn $_[0] unless $_[0] =~ /No library found for -lperl/
    };
    push(@cmd,ldopts());
}

if ($^O eq 'aix') { # AIX needs an explicit symbol export list.
    my ($perl_exp) = grep { -f } qw(perl.exp ../perl.exp);
    die "where is perl.exp?\n" unless defined $perl_exp;
    for (@cmd) {
        s!-bE:(\S+)!-bE:$perl_exp!;
    }
}

print "# @cmd"; # where is the newline coming from? ldopts()?
print "not " if system(join(' ',@cmd));
print "ok 1\n";

my $embed_test = File::Spec->catfile(File::Spec->curdir, "embed_test");

print "not " if system($embed_test);
print "ok 9\n";

unlink($exe,"embed_test.c");

# gcc -g -I.. -L../ -o perl_test perl_test.c -lperl `../perl -I../lib -MExtUtils::Embed -I../ -e ccopts -e ldopts`

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




