#!/usr/bin/perl -w                                         # -*- perl -*-
require Cwd;

BEGIN {
    require "t/pod2html-lib.pl";
}

use strict;
use Test::More tests => 1;

my $cwd = Cwd::cwd();

convert_n_test("htmlfeature", "misc pod-html features", 
 "--backlink", # doesn't appear b/c of --noindex
 "--css=style.css",
 "--header", # no styling b/c of --ccs
 "--htmldir=$cwd/t",
 "--noindex",
 "--podpath=t",
 "--podroot=$cwd",
 "--title=a title",
 
 );

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
<tr><td class="block" valign="middle">
<big><strong><span class="block">&nbsp;a title</span></strong></big>
</td></tr>
</table>


<!-- INDEX BEGIN -->
<div name="index">
<p><a name="__index__"></a></p>
<!--

<ul>

	<li><a href="#head_1">Head 1</a></li>
	<li><a href="#another_head_1">Another Head 1</a></li>
</ul>

-->


</div>
<!-- INDEX END -->

<p>
</p>
<h1><a name="head_1">Head 1</a></h1>
<p>A paragraph</p>
some html<p>Another paragraph</p>
<p>
</p>
<hr />
<h1><a name="another_head_1">Another Head 1</a></h1>
<p>some text and a link <a href="t/htmlcrossref.html">the htmlcrossref manpage</a></p>
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="block" valign="middle">
<big><strong><span class="block">&nbsp;a title</span></strong></big>
</td></tr>
</table>

</body>

</html>
