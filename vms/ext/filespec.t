#!./perl

BEGIN { unshift(@INC,'../lib') if -d '../lib'; }

use VMS::Filespec;

foreach (<DATA>) {
  chomp;
  s/\s*#.*//;
  next if /^\s*$/;
  push(@tests,$_);
}

require './test.pl';
plan(tests => scalar(2*@tests)+6);

foreach $test (@tests) {
  ($arg,$func,$expect) = split(/\s+/,$test);

  $rslt = eval "$func('$arg')";
  is($@, '', "eval func('$arg')");
  is($rslt, $expect, "  result");
}

$defwarn = <<'EOW';
# Note: This failure may have occurred because your default device
# was set using a non-concealed logical name.  If this is the case,
# you will need to determine by inspection that the two resultant
# file specifications shwn above are in fact equivalent.
EOW

is(rmsexpand('[]'),       "\U$ENV{DEFAULT}", 'rmsexpand()') || print $defwarn;
is(rmsexpand('from.here'),"\L$ENV{DEFAULT}from.here") || print $defwarn;
is(rmsexpand('from'),     "\L$ENV{DEFAULT}from")      || print $defwarn;

is(rmsexpand('from.here','cant:[get.there];2'),
   'cant:[get.there]from.here;2')                     || print $defwarn;


# Make sure we're using redirected mkdir, which strips trailing '/', since
# the CRTL's mkdir can't handle this.
ok(mkdir('testdir/',0777),      'using redirected mkdir()');
ok(rmdir('testdir/'),           '    rmdir()');

__DATA__

# Basic VMS to Unix filespecs
some_logical_name_not_likely:[where.over]the.rainbow	unixify	/some_logical_name_not_likely/where/over/the.rainbow
[.some_logical_name_not_likely.where.over]the.rainbow	unixify	some_logical_name_not_likely/where/over/the.rainbow
[-.some_logical_name_not_likely.where.over]the.rainbow	unixify	../some_logical_name_not_likely/where/over/the.rainbow
[.some_logical_name_not_likely.--.where.over]the.rainbow	unixify	some_logical_name_not_likely/../../where/over/the.rainbow
[.some_logical_name_not_likely...where.over]the.rainbow	unixify	some_logical_name_not_likely/.../where/over/the.rainbow
[...some_logical_name_not_likely.where.over]the.rainbow	unixify	.../some_logical_name_not_likely/where/over/the.rainbow
[.some_logical_name_not_likely.where.over...]the.rainbow	unixify	some_logical_name_not_likely/where/over/.../the.rainbow
[.some_logical_name_not_likely.where.over...]	unixify	some_logical_name_not_likely/where/over/.../
[.some_logical_name_not_likely.where.over.-]	unixify	some_logical_name_not_likely/where/over/../
[]	unixify		./
[-]	unixify		../
[--]	unixify		../../
[...]	unixify		.../

# and back again
/some_logical_name_not_likely/where/over/the.rainbow	vmsify	some_logical_name_not_likely:[where.over]the.rainbow
some_logical_name_not_likely/where/over/the.rainbow	vmsify	[.some_logical_name_not_likely.where.over]the.rainbow
../some_logical_name_not_likely/where/over/the.rainbow	vmsify	[-.some_logical_name_not_likely.where.over]the.rainbow
some_logical_name_not_likely/../../where/over/the.rainbow	vmsify	[-.where.over]the.rainbow
.../some_logical_name_not_likely/where/over/the.rainbow	vmsify	[...some_logical_name_not_likely.where.over]the.rainbow
some_logical_name_not_likely/.../where/over/the.rainbow	vmsify	[.some_logical_name_not_likely...where.over]the.rainbow
/some_logical_name_not_likely/.../where/over/the.rainbow	vmsify	some_logical_name_not_likely:[...where.over]the.rainbow
some_logical_name_not_likely/where/...	vmsify	[.some_logical_name_not_likely.where...]
/where/...	vmsify	where:[...]
.	vmsify	[]
..	vmsify	[-]
../..	vmsify	[--]
.../	vmsify	[...]
/	vmsify	sys$disk:[000000]

# Fileifying directory specs
down_logical_name_not_likely:[the.garden.path]	fileify	down_logical_name_not_likely:[the.garden]path.dir;1
[.down_logical_name_not_likely.the.garden.path]	fileify	[.down_logical_name_not_likely.the.garden]path.dir;1
/down_logical_name_not_likely/the/garden/path	fileify	/down_logical_name_not_likely/the/garden/path.dir;1
/down_logical_name_not_likely/the/garden/path/	fileify	/down_logical_name_not_likely/the/garden/path.dir;1
down_logical_name_not_likely/the/garden/path	fileify	down_logical_name_not_likely/the/garden/path.dir;1
down_logical_name_not_likely:[the.garden]path	fileify	down_logical_name_not_likely:[the.garden]path.dir;1
down_logical_name_not_likely:[the.garden]path.	fileify	# N.B. trailing . ==> null type
down_logical_name_not_likely:[the]garden.path	fileify	
/down_logical_name_not_likely/the/garden/path.	fileify	# N.B. trailing . ==> null type
/down_logical_name_not_likely/the/garden.path	fileify	

# and pathifying them
down_logical_name_not_likely:[the.garden]path.dir;1	pathify	down_logical_name_not_likely:[the.garden.path]
[.down_logical_name_not_likely.the.garden]path.dir	pathify	[.down_logical_name_not_likely.the.garden.path]
/down_logical_name_not_likely/the/garden/path.dir	pathify	/down_logical_name_not_likely/the/garden/path/
down_logical_name_not_likely/the/garden/path.dir	pathify	down_logical_name_not_likely/the/garden/path/
down_logical_name_not_likely:[the.garden]path	pathify	down_logical_name_not_likely:[the.garden.path]
down_logical_name_not_likely:[the.garden]path.	pathify	# N.B. trailing . ==> null type
down_logical_name_not_likely:[the]garden.path	pathify	
/down_logical_name_not_likely/the/garden/path.	pathify	# N.B. trailing . ==> null type
/down_logical_name_not_likely/the/garden.path	pathify	
down_logical_name_not_likely:[the.garden]path.dir;2	pathify	#N.B. ;2
__path	pathify	__path/
/down_logical_name_not_likely/the/garden/.	pathify	/down_logical_name_not_likely/the/garden/./
/down_logical_name_not_likely/the/garden/..	pathify	/down_logical_name_not_likely/the/garden/../
/down_logical_name_not_likely/the/garden/...	pathify	/down_logical_name_not_likely/the/garden/.../
path.notdir	pathify	

# Both VMS/Unix and file/path conversions
down_logical_name_not_likely:[the.garden]path.dir;1	unixpath	/down_logical_name_not_likely/the/garden/path/
/down_logical_name_not_likely/the/garden/path	vmspath	down_logical_name_not_likely:[the.garden.path]
down_logical_name_not_likely:[the.garden.path]	unixpath	/down_logical_name_not_likely/the/garden/path/
down_logical_name_not_likely:[the.garden.path...]	unixpath	/down_logical_name_not_likely/the/garden/path/.../
/down_logical_name_not_likely/the/garden/path.dir	vmspath	down_logical_name_not_likely:[the.garden.path]
[.down_logical_name_not_likely.the.garden]path.dir	unixpath	down_logical_name_not_likely/the/garden/path/
down_logical_name_not_likely/the/garden/path	vmspath	[.down_logical_name_not_likely.the.garden.path]
__path	vmspath	[.__path]
/	vmspath	sys$disk:[000000]

# Redundant characters in Unix paths
//some_logical_name_not_likely/where//over/../the.rainbow	vmsify	some_logical_name_not_likely:[where]the.rainbow
/some_logical_name_not_likely/where//over/./the.rainbow	vmsify	some_logical_name_not_likely:[where.over]the.rainbow
..//../	vmspath	[--]
./././	vmspath	[]
./../.	vmsify	[-]
