#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bFile\/Glob\b/i) {
        print "1..0\n";
        exit 0;
    }
    print "1..11\n";
}
END {
    print "not ok 1\n" unless $loaded;
}
use File::Glob ':glob';
use Cwd ();
$loaded = 1;
print "ok 1\n";

sub array {
    return '(', join(", ", map {defined $_ ? "\"$_\"" : "undef"} @a), ")\n";
}

# look for the contents of the current directory
$ENV{PATH} = "/bin";
delete @ENV{BASH_ENV, CDPATH, ENV, IFS};
@correct = ();
if (opendir(D, ".")) {
   @correct = grep { !/^\./ } sort readdir(D);
   closedir D;
}
@a = File::Glob::glob("*", 0);
@a = sort @a;
if ("@a" ne "@correct" || GLOB_ERROR) {
    print "# |@a| ne |@correct|\nnot ";
}
print "ok 2\n";

# look up the user's home directory
# should return a list with one item, and not set ERROR
if ($^O ne 'MSWin32' && $^O ne 'VMS') {
  eval {
    ($name, $home) = (getpwuid($>))[0,7];
    1;
  } and do {
    @a = bsd_glob("~$name", GLOB_TILDE);
    if (scalar(@a) != 1 || $a[0] ne $home || GLOB_ERROR) {
	print "not ";
    }
  };
}
print "ok 3\n";

# check backslashing
# should return a list with one item, and not set ERROR
@a = bsd_glob('TEST', GLOB_QUOTE);
if (scalar @a != 1 || $a[0] ne 'TEST' || GLOB_ERROR) {
    local $/ = "][";
    print "# [@a]\n";
    print "not ";
}
print "ok 4\n";

# check nonexistent checks
# should return an empty list
# XXX since errfunc is NULL on win32, this test is not valid there
@a = bsd_glob("asdfasdf", 0);
if ($^O ne 'MSWin32' and scalar @a != 0) {
    print "# |@a|\nnot ";
}
print "ok 5\n";

# check bad protections
# should return an empty list, and set ERROR
if ($^O eq 'mpeix' or $^O eq 'MSWin32' or $^O eq 'os2' or $^O eq 'VMS'
    or $^O eq 'cygwin' or Cwd::cwd() =~ m#^/afs#s or not $>)
{
    print "ok 6 # skipped\n";
}
else {
    $dir = "pteerslt";
    mkdir $dir, 0;
    @a = bsd_glob("$dir/*", GLOB_ERR);
    #print "\@a = ", array(@a);
    rmdir $dir;
    if (scalar(@a) != 0 || GLOB_ERROR == 0) {
	print "not ";
    }
    print "ok 6\n";
}

# check for csh style globbing
@a = bsd_glob('{a,b}', GLOB_BRACE | GLOB_NOMAGIC);
unless (@a == 2 and $a[0] eq 'a' and $a[1] eq 'b') {
    print "not ";
}
print "ok 7\n";

@a = bsd_glob(
    '{TES*,doesntexist*,a,b}',
    GLOB_BRACE | GLOB_NOMAGIC | ($^O eq 'VMS' ? GLOB_NOCASE : 0)
);

# Working on t/TEST often causes this test to fail because it sees Emacs temp
# and RCS files.  Filter them out, and .pm files too, and patch temp files.
@a = grep !/(,v$|~$|\.(pm|ori?g|rej)$)/, @a;

print "# @a\n";

unless (@a == 3
        and $a[0] eq ($^O eq 'VMS'? 'test.' : 'TEST')
        and $a[1] eq 'a'
        and $a[2] eq 'b')
{
    print "not ";
}
print "ok 8\n";

# "~" should expand to $ENV{HOME}
$ENV{HOME} = "sweet home";
@a = bsd_glob('~', GLOB_TILDE | GLOB_NOMAGIC);
unless (@a == 1 and $a[0] eq $ENV{HOME}) {
    print "not ";
}
print "ok 9\n";

# GLOB_ALPHASORT (default) should sort alphabetically regardless of case
mkdir "pteerslt", 0777;
chdir "pteerslt";
@f_ascii = qw(A.test B.test C.test a.test b.test c.test);
@f_alpha = qw(A.test a.test B.test b.test C.test c.test);
for (@f_ascii) {
    open T, "> $_";
    close T;
}
$pat = "*.test";
$ok = 1;
@g_ascii = bsd_glob($pat, 0);
for (@f_ascii) {
    $ok = 0 unless $_ eq shift @g_ascii;
}
print $ok ? "ok 10\n" : "not ok 10\n";
$ok = 1;
@g_alpha = bsd_glob($pat);
for (@f_alpha) {
    $ok = 0 unless $_ eq shift @g_alpha;
}
print $ok ? "ok 11\n" : "not ok 11\n";
unlink @f_ascii;
chdir "..";
rmdir "pteerslt";
