#!./perl

# Minimally test if dump() behaves as expected

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
    require './test.pl';

    skip_all_if_miniperl();
}

use Config;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

skip_all("only tested on devel builds")
  unless $Config{usedevel};

# there may be other operating systems where it makes sense, but
# there are some where it isn't, so limit the platforms we test
# this on
skip_all("no point in dumping on $^O")
  unless $^O =~ /^(linux|.*bsd|solaris)$/;

# execute in a work directory so File::Temp can clean up core dumps
my $tmp = tempdir(CLEANUP => 1);

my $start = getcwd;

chdir $tmp
  or skip_all("Cannot chdir to work directory");

plan(2);

# depending on how perl is built there may be extra output after
# the A such as "Aborted".

fresh_perl_like(<<'PROG', qr/\AA(?!B\z)/, {}, "plain dump quits");
++$|;
print qq(A);
dump;
print qq(B);
PROG

fresh_perl_like(<<'PROG', qr/A(?!B\z)/, {}, "dump with label quits");
++$|;
print qq(A);
dump foo;
foo:
print qq(B);
PROG

END {
  chdir $start;
}
