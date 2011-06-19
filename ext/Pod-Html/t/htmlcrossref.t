#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    require "t/pod2html-lib.pl";
}

use strict;
use Test::More tests => 1;

use File::Spec;
use Cwd;

# XXX Is there a better way to do this? I need a relative url to cwd because of
# --podpath and --podroot
# Remove root dir from path
my $cwd = substr(Cwd::cwd(), length(File::Spec->rootdir()));

convert_n_test("htmlcrossref", "html cross references", 
 "--podpath=$cwd/t:usr/share/perl",
 "--podroot=/",
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
  <li><a href="#TARGETS">TARGETS</a>
    <ul>
      <li><a href="#section1">section1</a></li>
    </ul>
  </li>
</ul>

<h1 id="NAME">NAME</h1>

<p>htmlcrossref - Test HTML cross reference links</p>

<h1 id="LINKS">LINKS</h1>

<p><a href="#section1">&quot;section1&quot;</a></p>

<p><a href="[CURRENTWORKINGDIRECTORY]/t/htmllink.html#section-2">&quot;section 2&quot; in htmllink</a></p>

<p><a href="#item1">&quot;item1&quot;</a></p>

<p><a href="#non-existant-section">&quot;non existant section&quot;</a></p>

<p><a href="/usr/share/perl/5.10.1/pod/perlvar.html">perlvar</a></p>

<p><a href="/usr/share/perl/5.10.1/pod/perlvar.html#pod-">&quot;$&quot;&quot; in perlvar</a></p>

<p><code>perlvar</code></p>

<p><code>perlvar/$&quot;</code></p>

<p><a href="/usr/share/perl/5.10.1/pod/perlpodspec.html#First:">&quot;First:&quot; in perlpodspec</a></p>

<p><code>perlpodspec/First:</code></p>

<p><a>notperldoc</a></p>

<h1 id="TARGETS">TARGETS</h1>

<h2 id="section1">section1</h2>

<p>This is section one.</p>

<dl>
<dt id="item1">item1</dt>

<dd>

<p>This is item one.</p>

</dd>
</dl>


</body>

</html>


