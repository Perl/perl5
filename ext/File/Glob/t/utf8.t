use File::Glob qw(:globally :utf8);

# Can't really depend on Tru64 UTF-8 filenames being so must just see
# that things don't crash and that *if* UTF-8 were to be received, it's
# valid.  (Maybe later add checks that are run if we are on NTFS/HFS+.)
# (see also t/op/readdir.t)

print "1..2\n";

my $a = <*>;

print utf8::valid($a) ? "ok 1\n" : "not ok 1\n";

my @a=<*>;

print utf8::valid($a[0]) ? "ok 2\n" : "not ok 2\n";

