require Cwd;
require Pod::Html;
require Config;
use File::Spec::Functions;

sub convert_n_test {
    my($podfile, $testname) = @_;

    my $cwd = Cwd::cwd();
    my $base_dir = catdir $cwd, "..", "lib", "Pod";
    my $new_dir  = catdir $base_dir, "t";
    my $infile   = catfile $new_dir, "$podfile.pod";
    my $outfile  = catfile $new_dir, "$podfile.html";

    Pod::Html::pod2html(
        "--podpath=t",
        "--podroot=$base_dir",
        "--htmlroot=/",
        "--infile=$infile",
        "--outfile=$outfile"
    );


    local $/;
    # expected
    my $expect = <DATA>;
    $expect =~ s/\[PERLADMIN\]/$Config::Config{perladmin}/;

    # result
    open my $in, $outfile or die "cannot open $outfile: $!";
    my $result = <$in>;
    close $in;

    is($expect, $result, $testname);

}

1;
