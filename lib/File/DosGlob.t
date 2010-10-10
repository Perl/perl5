#!./perl

#
# test glob() in File::DosGlob
#

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..17\n";

# override it in main::
use File::DosGlob 'glob';

require Cwd;

# test if $_ takes as the default
my $expected;
if ($^O eq 'MacOS') {
    $expected = $_ = ":op:a*.t";
} else {
    $expected = $_ = "op/a*.t";
}
my @r = glob;
print "not " if $_ ne $expected;
print "ok 1\n";
print "# |@r|\nnot " if @r < 9;
print "ok 2\n";

# check if <*/*> works
if ($^O eq 'MacOS') {
    @r = <:*:a*.t>;
} else {
    @r = <*/a*.t>;
}
# atleast {argv,abbrev,anydbm,autoloader,append,arith,array,assignwarn,auto}.t
print "# |@r|\nnot " if @r < 9;
print "ok 3\n";
my $r = scalar @r;

# check if scalar context works
@r = ();
while (defined($_ = ($^O eq 'MacOS') ? <:*:a*.t> : <*/a*.t>)) {
    print "# $_\n";
    push @r, $_;
}
print "not " if @r != $r;
print "ok 4\n";

# check if list context works
@r = ();
if ($^O eq 'MacOS') {
    for (<:*:a*.t>) {
    	print "# $_\n";
    	push @r, $_;
    }
} else {
    for (<*/a*.t>) {
    	print "# $_\n";
    	push @r, $_;
    }
}
print "not " if @r != $r;
print "ok 5\n";

# test if implicit assign to $_ in while() works
@r = ();
if ($^O eq 'MacOS') {
    while (<:*:a*.t>) {
    	print "# $_\n";
	push @r, $_;
    }
} else {
    while (<*/a*.t>) {
    	print "# $_\n";
	push @r, $_;
    }
}
print "not " if @r != $r;
print "ok 6\n";

# test if explicit glob() gets assign magic too
my @s = ();
my $pat = ($^O eq 'MacOS') ? ':*:a*.t': '*/a*.t';
while (glob ($pat)) {
    print "# $_\n";
    push @s, $_;
}
print "not " if "@r" ne "@s";
print "ok 7\n";

# how about in a different package, like?
package Foo;
use File::DosGlob 'glob';
@s = ();
$pat = $^O eq 'MacOS' ? ':*:a*.t' : '*/a*.t';
while (glob($pat)) {
    print "# $_\n";
    push @s, $_;
}
print "not " if "@r" ne "@s";
print "ok 8\n";

# test if different glob ops maintain independent contexts
@s = ();
if ($^O eq 'MacOS') {
    while (<:*:a*.t>) {
	my $i = 0;
	print "# $_ <";
	push @s, $_;
	while (<:*:b*.t>) {
	    print " $_";
	    $i++;
	}
	print " >\n";
    }
} else {
    while (<*/a*.t>) {
	my $i = 0;
	print "# $_ <";
	push @s, $_;
	while (<*/b*.t>) {
	    print " $_";
	    $i++;
	}
	print " >\n";
    }
}
print "not " if "@r" ne "@s";
print "ok 9\n";

# how about a global override, hm?
eval <<'EOT';
use File::DosGlob 'GLOBAL_glob';
package Bar;
@s = ();
if ($^O eq 'MacOS') {
    while (<:*:a*.t>) {
	my $i = 0;
	print "# $_ <";
	push @s, $_;
	while (glob ':*:b*.t') {
	    print " $_";
	    $i++;
	}
	print " >\n";
    }
} else {
    while (<*/a*.t>) {
	my $i = 0;
	print "# $_ <";
	push @s, $_;
	while (glob '*/b*.t') {
	    print " $_";
	    $i++;
	}
	print " >\n";
    }
}
print "not " if "@r" ne "@s";
print "ok 10\n";
EOT

# Test that a glob pattern containing ()'s works.
# NB. The spaces in the glob patterns need to be backslash escaped.
my $filename_containing_parens = "foo (123) bar";
if (open(TOUCH, ">", $filename_containing_parens)) {
    close(TOUCH);

    @r = ();
    eval { @r = File::DosGlob::glob("foo\\ (*") };
    print +($@ ? "not " : ""), "ok 11\n";
    print "not " unless (@r == 1 and $r[0] eq $filename_containing_parens);
    print "ok 12\n";

    @r = ();
    eval { @r = File::DosGlob::glob("*)\\ bar") };
    print +($@ ? "not " : ""), "ok 13\n";
    print "not " unless (@r == 1 and $r[0] eq $filename_containing_parens);
    print "ok 14\n";

    @r = ();
    eval { @r = File::DosGlob::glob("foo\\ (1*3)\\ bar") };
    print +($@ ? "not " : ""), "ok 15\n";
    print "not " unless (@r == 1 and $r[0] eq $filename_containing_parens);
    print "ok 16\n";

    1 while unlink $filename_containing_parens;
}
else {
    for (11..16) {
        print "ok $_ # skip - can't create '$filename_containing_parens': $!\n";
    }
}

# Test the globbing of a drive relative pattern such as "c:*.pl".
# NB. previous versions of DosGlob inserted "./ after the drive letter to
# make the expansion process work correctly. However, while it is harmless,
# there is no reason for it to be in the result.
my $cwd = Cwd::cwd();
if ($cwd =~ /^([a-zA-Z]:)/) {
    my $drive = $1;
    @r = ();
    # This assumes we're in the "t" directory.
    eval { @r = File::DosGlob::glob("${drive}io/*.t") };
    print +((@r and !grep !m|^${drive}io/[^/]*\.t$|, @r) ? "" : "not "), "ok 17\n";
} else {
    print "ok 17\n";
}
