#!perl -w
use File::Spec::Functions;
use Mac::Glue;
use Mac::InternetConfig;
$app = MacPerl::Ask('Enter the name of a glue:') or exit;
($app1 = $app) =~ tr/ /_/;
($app2 = $app) =~ tr/_/ /;

OUTER: for my $d (map { "$ENV{MACGLUEDIR}$_" } '', 'dialects', 'additions') {
    for ($app, $app1, $app2) {
        my $f = catfile($d, "$_.pod");
        if (-e $f) {
            $file = $f;
            $file =~ tr|:|/|;
            last OUTER;
        }
    }
}

if ($file) {
    GetURL "pod:///$file";
} else {
    MacPerl::Answer "'$app' not found.";
}
