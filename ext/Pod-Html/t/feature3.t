BEGIN {
    use File::Spec::Functions ':ALL';
    @INC = map { rel2abs($_) }
             (qw| ./lib ./t/lib ../../lib |);
}

use strict;
use warnings;
use Test::More;
use Testing qw( setup_testing_dir xconvert );
use Cwd;

my $debug = 0;
my $startdir = cwd();
END { chdir($startdir) or die("Cannot change back to $startdir: $!"); }
my ($expect_raw, $args);
{ local $/; $expect_raw = <DATA>; }

my $tdir = setup_testing_dir( {
    debug       => $debug,
} );

my $cwd = cwd();

$args = {
    podstub => "feature3",
    description => "nobacklink",
    expect => $expect_raw,
    p2h => {
        css             => 'style.css',
        header          => 1, # no styling b/c of --ccs
        htmldir         => catdir($cwd, 't'),
        nobacklink      => 1,
        noindex         => 1,
        noverbose       => 1,
        podpath         => 't',
        podroot         => $cwd,
        recurse         => 1,
        title           => 'a title',
        quiet           => 1,
    },
    debug => $debug,
};
xconvert($args);

done_testing;

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>a title</title>
<link rel="stylesheet" href="style.css" type="text/css" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body>
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" valign="middle">
<big><strong><span class="_podblock_">&nbsp;a title</span></strong></big>
</td></tr>
</table>



<h1 id="Head-1">Head 1</h1>

<p>A paragraph</p>



some html

<p>Another paragraph</p>

<h1 id="Another-Head-1">Another Head 1</h1>

<p>some text and a link <a href="t/crossref.html">crossref</a></p>

<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" valign="middle">
<big><strong><span class="_podblock_">&nbsp;a title</span></strong></big>
</td></tr>
</table>

</body>

</html>


