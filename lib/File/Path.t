# Path.t -- tests for module File::Path

use strict;

use Test::More tests => 72;

BEGIN {
    use_ok('File::Path');
    use_ok('File::Spec::Functions');
}

eval "use Test::Output";
my $has_Test_Output = $@ ? 0 : 1;

# first check for stupid permissions second for full, so we clean up
# behind ourselves
for my $perm (0111,0777) {
    my $path = catdir(curdir(), "mhx", "bar");
    mkpath($path);
    chmod $perm, "mhx", $path;

    my $oct = sprintf('0%o', $perm);
    ok(-d "mhx", "mkdir parent dir $oct");
    ok(-d $path, "mkdir child dir $oct");

    rmtree("mhx");
    ok(! -e "mhx", "mhx does not exist $oct");
}

# find a place to work
my ($error, $list, $file, $message);
my $tmp_base = catdir(
    curdir(),
    sprintf( 'test-%x-%x-%x', time, $$, rand(99999) ),
);

# invent some names
my @dir = (
    catdir($tmp_base, qw(a b)),
    catdir($tmp_base, qw(a c)),
    catdir($tmp_base, qw(z b)),
    catdir($tmp_base, qw(z c)),
);

# create them
my @created = mkpath(@dir);

is(scalar(@created), 7, "created list of directories");

# pray for no race conditions blowing them out from under us
@created = mkpath([$tmp_base]);
is(scalar(@created), 0, "skipped making existing directory")
    or diag("unexpectedly recreated @created");

@created = mkpath('');
is(scalar(@created), 0, "Can't create a directory named ''");

my $dir;
my $dir2;

SKIP: {
    $dir = catdir($tmp_base, 'B');
    $dir2 = catdir($dir, updir());
    # IOW: File::Spec->catdir( qw(foo bar), File::Spec->updir ) eq 'foo'
    # rather than foo/bar/..    
    skip "updir() canonicalises path on this platform", 2
        if $dir2 eq $tmp_base;
        
    @created = mkpath($dir2, {mask => 0700});
    is(scalar(@created), 1, "make directory with trailing parent segment");
    is($created[0], $dir, "made parent");
};

my $count = rmtree({error => \$error});
is( $count, 0, 'rmtree of nothing, count of zero' );
is( scalar(@$error), 1, 'one diagnostic captureed' );
eval { ($file, $message) = each %{$error->[0]} }; # too early to die, just in case
is( $@, '', 'decoded diagnostic' );
is( $file, '', 'general diagnostic' );
is( $message, 'No root path(s) specified', 'expected diagnostic received' );

@created = mkpath($tmp_base, 0);
is(scalar(@created), 0, "skipped making existing directories (old style 1)")
    or diag("unexpectedly recreated @created");

$dir = catdir($tmp_base,'C');
@created = mkpath($tmp_base, $dir);
is(scalar(@created), 1, "created directory (new style 1)");
is($created[0], $dir, "created directory (new style 1) cross-check");

@created = mkpath($tmp_base, 0, 0700);
is(scalar(@created), 0, "skipped making existing directories (old style 2)")
    or diag("unexpectedly recreated @created");

$dir2 = catdir($tmp_base,'D');
@created = mkpath($tmp_base, $dir, $dir2);
is(scalar(@created), 1, "created directory (new style 2)");
is($created[0], $dir2, "created directory (new style 2) cross-check");

$count = rmtree($dir, 0);
is($count, 1, "removed directory (old style 1)");

$count = rmtree($dir2, 0, 1);
is($count, 1, "removed directory (old style 2)");

# mkdir foo ./E/../Y
# Y should exist
# existence of E is neither here nor there
$dir = catdir($tmp_base, 'E', updir(), 'Y');
@created =mkpath($dir);
cmp_ok(scalar(@created), '>=', 1, "made one or more dirs because of ..");
cmp_ok(scalar(@created), '<=', 2, "made less than two dirs because of ..");
ok( -d catdir($tmp_base, 'Y'), "directory after parent" );

@created = mkpath(catdir(curdir(), $tmp_base));
is(scalar(@created), 0, "nothing created")
    or diag(@created);

$dir  = catdir($tmp_base, 'a');
$dir2 = catdir($tmp_base, 'z');

rmtree( $dir, $dir2,
    {
        error     => \$error,
        result    => \$list,
        keep_root => 1,
    }
);

is(scalar(@$error), 0, "no errors unlinking a and z");
is(scalar(@$list),  4, "list contains 4 elements")
    or diag("@$list");

ok(-d $dir,  "dir a still exists");
ok(-d $dir2, "dir z still exists");

# borderline new-style heuristics
if (chdir $tmp_base) {
    pass("chdir to temp dir");
}
else {
    fail("chdir to temp dir: $!");
}

$dir   = catdir('a', 'd1');
$dir2  = catdir('a', 'd2');

@created = mkpath( $dir, 0, $dir2 );
is(scalar @created, 3, 'new-style 3 dirs created');

$count = rmtree( $dir, 0, $dir2, );
is($count, 3, 'new-style 3 dirs removed');

@created = mkpath( $dir, $dir2, 1 );
is(scalar @created, 3, 'new-style 3 dirs created (redux)');

$count = rmtree( $dir, $dir2, 1 );
is($count, 3, 'new-style 3 dirs removed (redux)');

@created = mkpath( $dir, $dir2 );
is(scalar @created, 2, 'new-style 2 dirs created');

$count = rmtree( $dir, $dir2 );
is($count, 2, 'new-style 2 dirs removed');

if (chdir updir()) {
    pass("chdir parent");
}
else {
    fail("chdir parent: $!");
}

# see what happens if a file exists where we want a directory
SKIP: {
    my $entry = catdir($tmp_base, "file");
    skip "Cannot create $entry", 4 unless open OUT, "> $entry";
    print OUT "test file, safe to delete\n", scalar(localtime), "\n";
    close OUT;
    ok(-e $entry, "file exists in place of directory");

    mkpath( $entry, {error => \$error} );
    is( scalar(@$error), 1, "caught error condition" );
    ($file, $message) = each %{$error->[0]};
    is( $entry, $file, "and the message is: $message");

    eval {@created = mkpath($entry, 0, 0700)};
    $error = $@;
    chomp $error; # just to remove silly # in TAP output
    cmp_ok( $error, 'ne', "", "no directory created (old-style) err=$error" )
        or diag(@created);
}

my $extra =  catdir(curdir(), qw(EXTRA 1 a));

SKIP: {
    skip "extra scenarios not set up, see eg/setup-extra-tests", 8
        unless -e $extra;

    my ($list, $err);
    $dir = catdir( 'EXTRA', '1' );
    rmtree( $dir, {result => \$list, error => \$err} );
    is(scalar(@$list), 2, "extra dir $dir removed");
    is(scalar(@$err), 1, "one error encountered");

    $dir = catdir( 'EXTRA', '3', 'N' );
    rmtree( $dir, {result => \$list, error => \$err} );
    is( @$list, 1, q{remove a symlinked dir} );
    is( @$err,  0, q{with no errors} );

    $dir = catdir('EXTRA', '3', 'S');
    rmtree($dir, {error => \$error});
    is( scalar(@$error), 2, 'two errors for an unreadable dir' );

    $dir = catdir( 'EXTRA', '4' );
    rmtree($dir,  {result => \$list, error => \$err} );
    is( @$list, 0, q{don't follow a symlinked dir} );
    is( @$err,  1, q{one error when removing a symlink in r/o dir} );
    eval { ($file, $message) = each %{$err->[0]} };
    is( $file, $dir, 'symlink reported in error' );
}

SKIP: {
    skip 'Test::Output not available', 10
        unless $has_Test_Output;

    SKIP: {
        $dir = catdir('EXTRA', '3');
        skip "extra scenarios not set up, see eg/setup-extra-tests", 2
            unless -e $dir;

        stderr_like( 
            sub {rmtree($dir, {})},
            qr{\ACan't remove directory \S+: .*? at \S+ line \d+\n},
            'rmtree with file owned by root'
        );

        stderr_like( 
            sub {rmtree('EXTRA', {})},
            qr{\ACan't make directory EXTRA read\+writeable: .*? at \S+ line \d+
(?:Can't remove directory EXTRA/\d: .*? at \S+ line \d+
)+Can't unlink file [^:]+: .*? at \S+ line \d+
Can't remove directory EXTRA: .*? at \S+ line \d+
and can't restore permissions to \d+
 at \S+ line \d+},
            'rmtree with insufficient privileges'
        );
    }

    my $base = catdir($tmp_base,'output');
    $dir  = catdir($base,'A');
    $dir2 = catdir($base,'B');

    stderr_like(
        \&rmtree,
        qr/\ANo root path\(s\) specified\b/,
        "rmtree of nothing carps sensibly"
    );

    stdout_is(
        sub {@created = mkpath($dir, 1)},
        "mkdir $base\nmkdir $dir\n",
        'mkpath verbose (old style 1)'
    );

    stdout_is(
        sub {@created = mkpath([$dir2], 1)},
        "mkdir $dir2\n",
        'mkpath verbose (old style 2)'
    );

    stdout_is(
        sub {$count = rmtree([$dir, $dir2], 1, 1)},
        "rmdir $dir\nrmdir $dir2\n",
        'rmtree verbose (old style)'
    );

    stdout_is(
        sub {@created = mkpath($dir, {verbose => 1, mask => 0750})},
        "mkdir $dir\n",
        'mkpath verbose (new style 1)'
    );

    stdout_is(
        sub {@created = mkpath($dir2, 1, 0771)},
        "mkdir $dir2\n",
        'mkpath verbose (new style 2)'
    );

    SKIP: {
        $file = catdir($dir2, "file");
        skip "Cannot create $file", 2 unless open OUT, "> $file";
        print OUT "test file, safe to delete\n", scalar(localtime), "\n";
        close OUT;

        ok(-e $file, "file created in directory");

        stdout_is(
            sub {$count = rmtree($dir, $dir2, {verbose => 1, safe => 1})},
            "rmdir $dir\nunlink $file\nrmdir $dir2\n",
            'rmtree safe verbose (new style)'
        );
    }
}

SKIP: {
    skip "extra scenarios not set up, see eg/setup-extra-tests", 6
        unless -d catdir(qw(EXTRA 1));

    rmtree 'EXTRA', {safe => 0, error => \$error};
    is( scalar(@$error), 7, 'seven deadly sins' );

    rmtree 'EXTRA', {safe => 1, error => \$error};
    is( scalar(@$error), 4, 'safe is better' );
    for (@$error) {
        ($file, $message) = each %$_;
        if ($file =~  /[123]\z/) {
            is(index($message, 'rmdir: '), 0, "failed to remove $file with rmdir")
                or diag($message);
        }
        else {
            is(index($message, 'unlink: '), 0, "failed to remove $file with unlink")
                or diag($message);
        }
    }
}

rmtree($tmp_base, {result => \$list} );
is(ref($list), 'ARRAY', "received a final list of results");
ok( !(-d $tmp_base), "test base directory gone" );
