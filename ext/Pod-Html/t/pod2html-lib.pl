require Cwd;
require Pod::Html;
require Config;
use File::Spec::Functions ':ALL';
use File::Path 'remove_tree';
use File::Copy;

# make_test_dir and rem_test_dir dynamically create and remove testdir/test.lib.
# it is created dynamically to pass t/filenames.t, which does not allow '.'s in
# filenames as '.' is the directory separator on VMS. All tests that require
# testdir/test.lib to be present are skipped if test.lib cannot be created.
sub make_test_dir {
    if (-d 'testdir/test.lib') {
        warn "Directory 'test.lib' exists (it shouldn't yet) - removing it";
        rem_test_dir();
    }
    mkdir('testdir/test.lib') or return "Could not make test.lib directory: $!\n";
    copy('testdir/perlpodspec-copy.pod', 'testdir/test.lib/podspec-copy.pod')
        or return "Could not copy perlpodspec-copy: $!";
    copy('testdir/perlvar-copy.pod', 'testdir/test.lib/var-copy.pod')
        or return "Could not copy perlvar-copy: $!";
    return 0;
}

sub rem_test_dir {
    remove_tree('testdir/test.lib')
        or warn "Error removing temporary directory 'testdir/test.lib'";
}

sub convert_n_test {
    my($podfile, $testname, @p2h_args) = @_;

    my $cwd = Cwd::cwd();
    my ($vol, $dir) = splitpath($cwd, 1);
    my $relcwd = substr($dir, length(File::Spec->rootdir()));
	
    my $new_dir  = catdir $cwd, "t";
    my $infile   = catfile $new_dir, "$podfile.pod";
    my $outfile  = catfile $new_dir, "$podfile.html";
    
    # To add/modify args to p2h, use @p2h_args
    Pod::Html::pod2html(
        "--infile=$infile",
        "--outfile=$outfile",
        "--podpath=t",
        "--htmlroot=/",
        "--podroot=$cwd",
        @p2h_args,
    );


    my ($expect, $result);
    {
	local $/;
	# expected
	$expect = <DATA>;
	$expect =~ s/\[PERLADMIN\]/$Config::Config{perladmin}/;
	$expect =~ s/\[RELCURRENTWORKINGDIRECTORY\]/$relcwd/g;
	if (ord("A") == 193) { # EBCDIC.
	    $expect =~ s/item_mat_3c_21_3e/item_mat_4c_5a_6e/;
	}

	# result
	open my $in, $outfile or die "cannot open $outfile: $!";
	$result = <$in>;
	close $in;
    }

    ok($expect eq $result, $testname) or do {
	my $diff = '/bin/diff';
	-x $diff or $diff = '/usr/bin/diff';
	if (-x $diff) {
	    my $expectfile = "pod2html-lib.tmp";
	    open my $tmpfile, ">", $expectfile or die $!;
	    print $tmpfile $expect;
	    close $tmpfile;
	    my $diffopt = $^O eq 'linux' ? 'u' : 'c';
	    open my $diff, "diff -$diffopt $expectfile $outfile |" or die $!;
	    print "# $_" while <$diff>;
	    close $diff;
	    unlink $expectfile;
	}
    };

    # pod2html creates these
    1 while unlink $outfile;
}

1;
