require Cwd;
require Pod::Html;
require Config;
use File::Spec::Functions;

sub convert_n_test {
    my($podfile, $testname, @p2h_args) = @_;

    my $cwd = Cwd::cwd();
    # XXX Is there a better way to do this? I need a relative url to cwd because of
	# --podpath and --podroot
	# Remove root dir from path
	my $rel_cwd = substr($cwd, length(File::Spec->rootdir()));
	
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
	$expect =~ s/\[CURRENTWORKINGDIRECTORY\]/$cwd/g;
	$expect =~ s/\[RELCURRENTWORKINGDIRECTORY\]/$rel_cwd/g;
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
