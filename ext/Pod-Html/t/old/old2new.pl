#!/usr/bin/perl
use 5.14.0;
use warnings;
$^I = '.bak'; # in place editng
$/ = undef; # slurp whole file

# Convert old Pod::Html tests to new Pod::Html tests
# Does basic conversion, simplifying the conversion by hand process
# XXX: Watch out for [(REL)CURRENTWORKINGDIR] being s///'d, put it back after copy/paste

my $bindex = <<INDEX;
<!-- INDEX BEGIN -->
<div name="index">
<p><a name="__index__"></a></p>

<ul>

INDEX

my $eindex = <<END_INDEX;
</div>
<!-- INDEX END -->

END_INDEX

while (<>) {
	# keep it [PERLADMIN]
	s#<link rev="made" href="mailto:.+?" />#<link rev="made" href="mailto:[PERLADMIN]" />#;
	
	s#<title>.+?</title>#<title></title>#;
	s#$bindex#\n<ul id="index">\n#;
	s#$eindex##;
	s#</html>#</html>\n\n#; # ::xhtml adds newlines
	
	s#<hr.*? />##g; # remove <hr>s
	s#<p>\n</p>##g; # remove <p></p>s
	s#(<p>[^\n].+?</p>)#$1\n#g; # space out <p>s
	s/">(.+?) in the (.+?) manpage/">&quot;$1&quot; in $2/g;
	s/the (.+?) manpage/$1/g;
	s#<em>(.+?)</em>#<a>$1</a>#g; # links not found


	# index elements
	# Note: only works for sections w/o inner <ul>s b/c new Pod::Html handles them differently
	s|<li><a href="#(.+?)">(??{ uc $1 })</a></li>|
		'<li><a href="#' . uc($1) . '">'. uc($1) . '</a></li>'|eg;
	
	# anchored =head1 -> id'd =head1
	s#<h(\d)><a name="(.+?)">(??{ uc $2 })</a></h\1>#
		"<h$1 id=\"" . uc($2) . '">' . uc($2) . "</h$1>\n"#eg;
	
	print;
}
