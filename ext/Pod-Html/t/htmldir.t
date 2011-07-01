#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    require "t/pod2html-lib.pl";
}

use strict;
use Test::More tests => 2;
use File::Spec::Functions;

use File::Spec;
use Cwd;

my ($v, $d) = splitpath(cwd(), 1);
my $relcwd = substr($d, length(File::Spec->rootdir()));

my $data_pos = tell DATA; # to read <DATA> twice

my $podpath = catdir($relcwd, 't') . ":" . catfile($relcwd, 'test.lib');

convert_n_test("htmldir", "test --htmldir and --htmlroot 1a", 
 "--podpath=$podpath",
 "--podroot=$v".File::Spec->rootdir,
# "--podpath=t",
# "--htmlroot=/test/dir",
 "--htmldir=t",
);

seek DATA, $data_pos, 0; # to read <DATA> twice (expected output is the same)

my $htmldir = catfile $relcwd, 't';

convert_n_test("htmldir", "test --htmldir and --htmlroot 1b", 
 "--podpath=$relcwd",
 "--podroot=$v".File::Spec->rootdir,
 "--htmldir=$htmldir",
 "--htmlroot=/",
);

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body style="background-color: white">



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#LINKS">LINKS</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>htmldir - Test --htmldir feature</p>

<h1 id="LINKS">LINKS</h1>

<p>Normal text, a <a>link</a> to nowhere,</p>

<p>a link to <a href="/[RELCURRENTWORKINGDIRECTORY]/test.lib/perlvar.html">perlvar</a>,</p>

<p><a href="/[RELCURRENTWORKINGDIRECTORY]/t/htmlescp.html">htmlescp</a>,</p>

<p><a href="/[RELCURRENTWORKINGDIRECTORY]/t/htmlfeature.html#Another-Head-1">&quot;Another Head 1&quot; in htmlfeature</a>,</p>

<p>and another <a href="/[RELCURRENTWORKINGDIRECTORY]/t/htmlfeature.html#Another-Head-1">&quot;Another Head 1&quot; in htmlfeature</a>.</p>


</body>

</html>


