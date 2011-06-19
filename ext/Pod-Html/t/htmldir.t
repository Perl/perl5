#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    require "t/pod2html-lib.pl";
}

use strict;
use Test::More tests => 2;

use File::Spec;
use Cwd;

# XXX Is there a better way to do this? I need a relative url to cwd because of
# --podpath and --podroot
# Remove root dir from path
my $cwd = substr(Cwd::cwd(), length(File::Spec->rootdir()));

my $data_pos = tell DATA; # to read <DATA> twice

convert_n_test("htmldir", "test --htmldir and --htmlroot 1a", 
 "--podpath=$cwd/t:usr/share/perl",
 "--podroot=/",
# "--podpath=t",
# "--htmlroot=/test/dir",
 "--htmldir=t",
);

seek DATA, $data_pos, 0; # to read <DATA> twice (expected output is the same)

convert_n_test("htmldir", "test --htmldir and --htmlroot 1b", 
 "--podpath=$cwd:usr/share/perl",
 "--podroot=/",
 "--htmldir=$cwd/t",
 "--htmlroot=/",
);

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>htmldir - Test --htmldir feature</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body style="background-color: white">


<!-- INDEX BEGIN -->
<div name="index">
<p><a name="__index__"></a></p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#links">LINKS</a></li>
</ul>

<hr name="index" />
</div>
<!-- INDEX END -->

<p>
</p>
<h1><a name="name">NAME</a></h1>
<p>htmldir - Test --htmldir feature</p>
<p>
</p>
<hr />
<h1><a name="links">LINKS</a></h1>
<p>Normal text, a <em>link</em> to nowhere,</p>
<p>a link to <a href="/usr/share/perl/5.10.1/pod/perlvar.html">the perlvar manpage</a>,</p>
<p><a href="[CURRENTWORKINGDIRECTORY]/t/htmlescp.html">the htmlescp manpage</a>,</p>
<p><a href="[CURRENTWORKINGDIRECTORY]/t/htmlfeature.html#another_head_1">Another Head 1 in the htmlfeature manpage</a>,</p>
<p>and another <a href="[CURRENTWORKINGDIRECTORY]/t/htmlfeature.html#another_head_1">Another Head 1 in the htmlfeature manpage</a>.</p>

</body>

</html>
