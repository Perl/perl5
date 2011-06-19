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
<h1><a name="links">LINKS</a></h1>
<p><a href="#section1">section1</a></p>
<p><a href="[CURRENTWORKINGDIRECTORY]/t/htmllink.html#section_2">section 2 in the htmllink manpage</a></p>
<p><a href="#item1">item1</a></p>
<p><a href="#non_existant_section">non existant section</a></p>
<p><a href="/usr/share/perl/5.10.1/pod/perlvar.html">the perlvar manpage</a></p>
<p><a href="/usr/share/perl/5.10.1/pod/perlvar.html#_">$&quot; in the perlvar manpage</a></p>
<p><code>perlvar</code></p>
<p><code>perlvar/$&quot;</code></p>
<p><a href="/usr/share/perl/5.10.1/pod/perlpodspec.html#first_">First: in the perlpodspec manpage</a></p>
<p><code>perlpodspec/First:</code></p>
<p><em>notperldoc</em></p>
<p>
</p>
<hr />
<h1><a name="targets">TARGETS</a></h1>
<p>
</p>
<h2><a name="section1">section1</a></h2>
<p>This is section one.</p>
<dl>
<dt><strong><a name="item1" class="item">item1</a></strong></dt>

<dd>
<p>This is item one.</p>
</dd>
</dl>

</body>

</html>
