#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

eval 'opendir(NOSUCH, "no/such/directory");';
if ($@) { print "1..0\n"; exit; }

print "1..6\n";

for $i (1..2000) {
    local *OP;
    opendir(OP, "op") or die "can't opendir: $!";
    # should auto-closedir() here
}

if (opendir(OP, "op")) { print "ok 1\n"; } else { print "not ok 1\n"; }
@D = grep(/^[^\.].*\.t$/i, readdir(OP));
closedir(OP);

##
## This range will have to adjust as the number of tests expands,
## as it's counting the number of .t files in src/t
##
my ($min, $max) = (115, 135);
if (@D > $min && @D < $max) { print "ok 2\n"; }
else {
    printf "not ok 2 # counting op/*.t, expect $min < %d < $max files\n",
      scalar @D;
}

@R = sort @D;
@G = sort <op/*.t>;
if ($G[0] =~ m#.*\](\w+\.t)#i) {
    # grep is to convert filespecs returned from glob under VMS to format
    # identical to that returned by readdir
    @G = grep(s#.*\](\w+\.t).*#op/$1#i,<op/*.t>);
}
while (@R && @G && "op/".$R[0] eq $G[0]) {
	shift(@R);
	shift(@G);
}
if (@R == 0 && @G == 0) { print "ok 3\n"; } else { print "not ok 3\n"; }

# Can't really depend on Tru64 UTF-8 filenames being so must just see
# that things don't crash and that *if* UTF-8 were to be received, it's
# valid.  (Maybe later add checks that are run if we are on NTFS/HFS+.)
# (see also ext/File/Glob/t/utf8.t)

opendir(OP, ":utf8", "op");

my $a = readdir(OP);

print utf8::valid($a) ? "ok 4\n" : "not ok 4\n";

my @a = readdir(OP);

print utf8::valid($a[0]) ? "ok 5\n" : "not ok 5\n";

# But we can check for bogus mode arguments.

eval { opendir(OP, ":foo", "op") };

print $@ =~ /Unknown discipline ':foo'/ ? "ok 6\n" : "not ok 6\n";

