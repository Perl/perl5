#!/local/bin/perl -w

use URI::URL qw(url);
use URI::Escape qw(uri_escape uri_unescape);

# _expect()
#
# Handy low-level object method tester which we insert as a method
# in the URI::URL class
#
sub URI::URL::_expect {
    my($self, $method, $expect, @args) = @_;
    my $result = $self->$method(@args);
    $expect = 'UNDEF' unless defined $expect;
    $result = 'UNDEF' unless defined $result;
    return 1 if $expect eq $result;
    warn "'$self'->$method(@args) = '$result' " .
		"(expected '$expect')\n";
    $self->print_on('STDERR');
    die "Test Failed";
}

package main;

# Must ensure that there is no relative paths in @INC because we will
# chdir in the newlocal tests.
unless ($^O eq "MacOS") {
chomp($pwd = ($^O =~ /mswin32/i ? `cd` : $^O eq 'VMS' ? `show default` : `pwd`));
if ($^O eq 'VMS') {
    $pwd =~ s#^\s+##;
    $pwd = VMS::Filespec::unixpath($pwd);
    $pwd =~ s#/$##;
}
for (@INC) {
    my $x = $_;
    $x = VMS::Filespec::unixpath($x) if $^O eq 'VMS';
    next if $x =~ m|^/| or $^O =~ /os2|mswin32/i and $x =~ m|^\w:[\\/]|;
    print "Turn lib path $x into $pwd/$x\n";
    $_ = "$pwd/$x";

}
}

$| = 1;

print "1..8\n";  # for Test::Harness

# Do basic tests first.
# Dies if an error has been detected, prints "ok" otherwise.

print "Self tests for URI::URL version $URI::URL::VERSION...\n";

eval { scheme_parse_test(); };
print "not " if $@;
print "ok 1\n";

eval { parts_test(); };
print "not " if $@;
print "ok 2\n";

eval { escape_test(); };
print "not " if $@;
print "ok 3\n";

eval { newlocal_test(); };
print "not " if $@;
print "ok 4\n";

eval { absolute_test(); };
print "not " if $@;
print "ok 5\n";

eval { eq_test(); };
print "not " if $@;
print "ok 6\n";

# Let's test making our own things
URI::URL::strict(0);
# This should work after URI::URL::strict(0)
$url = new URI::URL "x-myscheme:something";
# Since no implementor is registered for 'x-myscheme' then it will
# be handled by the URI::URL::_generic class
$url->_expect('as_string' => 'x-myscheme:something');
$url->_expect('path' => 'something');
URI::URL::strict(1);

=comment

# Let's try to make our URL subclass
{
    package MyURL;
    @ISA = URI::URL::implementor();

    sub _parse {
	my($self, $init) = @_;
	$self->URI::URL::_generic::_parse($init, qw(netloc path));
    }

    sub foo {
	my $self = shift;
	print ref($self)."->foo called for $self\n";
    }
}
# Let's say that it implements the 'x-a+b.c' scheme (alias 'x-foo')
URI::URL::implementor('x-a+b.c', 'MyURL');
URI::URL::implementor('x-foo', 'MyURL');

# Now we are ready to try our new URL scheme
$url = new URI::URL 'x-a+b.c://foo/bar;a?b';
$url->_expect('as_string', 'x-a+b.c://foo/bar;a?b');
$url->_expect('path', '/bar;a?b');
$url->foo;
$newurl = new URI::URL 'xxx', $url;
$newurl->foo;
$url = new URI::URL 'yyy', 'x-foo:';
$url->foo;

=cut

print "ok 7\n";

# Test the new wash&go constructor
print "not " if url("../foo.html", "http://www.sn.no/a/b")->abs->as_string
		ne 'http://www.sn.no/foo.html';
print "ok 8\n";

print "URI::URL version $URI::URL::VERSION ok\n";

exit 0;




#####################################################################
#
# scheme_parse_test()
#
# test parsing and retrieval methods

sub scheme_parse_test {

    print "scheme_parse_test:\n";

    $tests = {
	'hTTp://web1.net/a/b/c/welcome#intro'
	=> {    'scheme'=>'http', 'host'=>'web1.net', 'port'=>80,
		'path'=>'/a/b/c/welcome', 'frag'=>'intro','query'=>undef,
		'epath'=>'/a/b/c/welcome', 'equery'=>undef,
		'params'=>undef, 'eparams'=>undef,
		'as_string'=>'http://web1.net/a/b/c/welcome#intro',
		'full_path' => '/a/b/c/welcome' },

	'http://web:1/a?query+text'
	=> {    'scheme'=>'http', 'host'=>'web', 'port'=>1,
		'path'=>'/a', 'frag'=>undef, 'query'=>'query+text' },

	'http://web.net/'
	=> {    'scheme'=>'http', 'host'=>'web.net', 'port'=>80,
		'path'=>'/', 'frag'=>undef, 'query'=>undef,
		'full_path' => '/',
		'as_string' => 'http://web.net/' },

	'http://web.net'
	=> {    'scheme'=>'http', 'host'=>'web.net', 'port'=>80,
		'path'=>'/', 'frag'=>undef, 'query'=>undef,
		'full_path' => '/',
		'as_string' => 'http://web.net/' },

	'http:0'
	 => {   'scheme'=>'http', 'path'=>'0', 'query'=>undef,
		'as_string'=>'http:0', 'full_path'=>'0', },

	'http:/0?0'
	 => {   'scheme'=>'http', 'path'=>'/0', 'query'=>'0',
		'as_string'=>'http:/0?0', 'full_path'=>'/0?0', },

	'http://0:0/0/0;0?0#0'
	 => {   'scheme'=>'http', 'host'=>'0', 'port'=>'0',
		'path' => '/0/0', 'query'=>'0', 'params'=>'0',
		'netloc'=>'0:0',
		'frag'=>0, 'as_string'=>'http://0:0/0/0;0?0#0' },

	'ftp://0%3A:%40@h:0/0?0'
	=>  {   'scheme'=>'ftp', 'user'=>'0:', 'password'=>'@',
		'host'=>'h', 'port'=>'0', 'path'=>'/0?0',
		'query'=>'0', params=>undef,
		'netloc'=>'0%3A:%40@h:0',
		'as_string'=>'ftp://0%3A:%40@h:0/0?0' },

	'ftp://usr:pswd@web:1234/a/b;type=i'
	=> {    'host'=>'web', 'port'=>1234, 'path'=>'/a/b',
		'user'=>'usr', 'password'=>'pswd',
		'params'=>'type=i',
		'as_string'=>'ftp://usr:pswd@web:1234/a/b;type=i' },

	'ftp://host/a/b'
	=> {    'host'=>'host', 'port'=>21, 'path'=>'/a/b',
		'user'=>'anonymous',
		'as_string'=>'ftp://host/a/b' },

	'file://host/fseg/fs?g/fseg'
	# don't escape ? for file: scheme
	=> {    'host'=>'host', 'path'=>'/fseg/fs?g/fseg',
		'as_string'=>'file://host/fseg/fs?g/fseg' },

	'gopher://host'
	=> {     'gtype'=>'1', 'as_string' => 'gopher://host', },

	'gopher://host/'
	=> {     'gtype'=>'1', 'as_string' => 'gopher://host/', },

	'gopher://gopher/2a_selector'
	=> {    'gtype'=>'2', 'selector'=>'a_selector',
		'as_string' => 'gopher://gopher/2a_selector', },

	'mailto:libwww-perl@ics.uci.edu'
	=> {    'address'       => 'libwww-perl@ics.uci.edu',
		'encoded822addr'=> 'libwww-perl@ics.uci.edu',
#		'user'          => 'libwww-perl',
#		'host'          => 'ics.uci.edu',
		'as_string'     => 'mailto:libwww-perl@ics.uci.edu', },

	'news:*'
	=> {    'groupart'=>'*', 'group'=>'*', as_string=>'news:*' },
	'news:comp.lang.perl'
	=> {    'group'=>'comp.lang.perl' },
	'news:perl-faq/module-list-1-794455075@ig.co.uk'
	=> {    'article'=>
		    'perl-faq/module-list-1-794455075@ig.co.uk' },

	'nntp://news.com/comp.lang.perl/42'
	=> {    'group'=>'comp.lang.perl', }, #'digits'=>42 },

	'telnet://usr:pswd@web:12345/'
	=> {    'user'=>'usr', 'password'=>'pswd', 'host'=>'web' },
	'rlogin://aas@a.sn.no'
	=> {    'user'=>'aas', 'host'=>'a.sn.no' },
#	'tn3270://aas@ibm'
#	=> {    'user'=>'aas', 'host'=>'ibm',
#		'as_string'=>'tn3270://aas@ibm/'},

#	'wais://web.net/db'
#	=> { 'database'=>'db' },
#	'wais://web.net/db?query'
#	=> { 'database'=>'db', 'query'=>'query' },
#	'wais://usr:pswd@web.net/db/wt/wp'
#	=> {    'database'=>'db', 'wtype'=>'wt', 'wpath'=>'wp',
#		'password'=>'pswd' },
    };

    foreach $url_str (sort keys %$tests ){
	print "Testing '$url_str'\n";
	my $url = new URI::URL $url_str;
	my $tests = $tests->{$url_str};
	while( ($method, $exp) = each %$tests ){
	    $exp = 'UNDEF' unless defined $exp;
	    $url->_expect($method, $exp);
	}
    }
}


#####################################################################
#
# parts_test()          (calls netloc_test test)
#
# Test individual component part access functions
#
sub parts_test {
    print "parts_test:\n";

    # test storage part access/edit methods (netloc, user, password,
    # host and port are tested by &netloc_test)

    $url = new URI::URL 'file://web/orig/path';
    $url->scheme('http');
    $url->path('1info');
    $url->query('key words');
    $url->frag('this');
    $url->_expect('as_string' => 'http://web/1info?key%20words#this');

    $url->epath('%2f/%2f');
    $url->equery('a=%26');
    $url->_expect('full_path' => '/%2f/%2f?a=%26');

    # At this point it should be impossible to access the members path()
    # and query() without complaints.
    eval { my $p = $url->path; print "Path is $p\n"; };
    die "Path exception failed" unless $@;
    eval { my $p = $url->query; print "Query is $p\n"; };
    die "Query exception failed" unless $@;

    # but we should still be able to set it 
    $url->path("howdy");
    $url->_expect('as_string' => 'http://web/howdy?a=%26#this');

    # Test the path_components function
    $url = new URI::URL 'file:%2f/%2f';
    my $p;
    $p = join('-', $url->path_components);
    die "\$url->path_components returns '$p', expected '/-/'"
      unless $p eq "/-/";
    $url->host("localhost");
    $p = join('-', $url->path_components);
    die "\$url->path_components returns '$p', expected '-/-/'"
      unless $p eq "-/-/";
    $url->epath("/foo/bar/");
    $p = join('-', $url->path_components);
    die "\$url->path_components returns '$p', expected '-foo-bar-'"
      unless $p eq "-foo-bar-";
    $url->path_components("", "/etc", "\0", "..", "øse", "");
    $url->_expect('full_path' => '/%2Fetc/%00/../%F8se/');

    # Setting undef
    $url = new URI::URL 'http://web/p;p?q#f';
    $url->epath(undef);
    $url->equery(undef);
    $url->eparams(undef);
    $url->frag(undef);
    $url->_expect('as_string' => 'http://web');

    # Test http query access methods
    $url->keywords('dog');
    $url->_expect('as_string' => 'http://web?dog');
    $url->keywords(qw(dog bones));
    $url->_expect('as_string' => 'http://web?dog+bones');
    $url->keywords(0,0);
    $url->_expect('as_string' => 'http://web?0+0');
    $url->keywords('dog', 'bones', '#+=');
    $url->_expect('as_string' => 'http://web?dog+bones+%23%2B%3D');
    $a = join(":", $url->keywords);
    die "\$url->keywords did not work (returned '$a')" unless $a eq 'dog:bones:#+=';
    # calling query_form is an error
#    eval { my $foo = $url->query_form; };
#    die "\$url->query_form should croak since query contains keywords not a form."
#      unless $@;

    $url->query_form(a => 'foo', b => 'bar');
    $url->_expect('as_string' => 'http://web?a=foo&b=bar');
    my %a = $url->query_form;
    die "\$url->query_form did not work"
      unless $a{a} eq 'foo' && $a{b} eq 'bar';

    $url->query_form(a => undef, a => 'foo', '&=' => '&=+');
    $url->_expect('as_string' => 'http://web?a=&a=foo&%26%3D=%26%3D%2B');

    my @a = $url->query_form;
    die "Wrong length" unless @a == 6;
    die "Bad keys from query_form"
      unless $a[0] eq 'a' && $a[2] eq 'a' && $a[4] eq '&=';
    die "Bad values from query_form"
      unless $a[1] eq '' && $a[3] eq 'foo' && $a[5] eq '&=+';

    # calling keywords is an error
#    eval { my $foo = $url->keywords; };
#    die "\$url->keywords should croak when query is a form"
#      unless $@;
    # Try this odd one
    $url->equery('&=&=b&a=&a&a=b=c&&a=b');
    @a = $url->query_form;
    #print join(":", @a), "\n";
    die "Wrong length" unless @a == 16;
    die "Wrong sequence" unless $a[4]  eq ""  && $a[5]  eq "b" &&
                                $a[10] eq "a" && $a[11] eq "b=c";

    # Try array ref values in the key value pairs
    $url->query_form(a => ['foo', 'bar'], b => 'foo', c => ['bar', 'foo']);
    $url->_expect('as_string', 'http://web?a=foo&a=bar&b=foo&c=bar&c=foo');


    netloc_test();
    port_test();

    $url->query(undef);
    $url->_expect('query', undef);

    $url = new URI::URL 'gopher://gopher/';
    $url->port(33);
    $url->gtype("3");
    $url->selector("S");
    $url->search("query");
    $url->_expect('as_string', 'gopher://gopher:33/3S%09query');

    $url->epath("45%09a");
    $url->_expect('gtype' => '4');
    $url->_expect('selector' => '5');
    $url->_expect('search' => 'a');
    $url->_expect('string' => undef);
    $url->_expect('path' => "/45\ta");
#    $url->path("00\t%09gisle");
#    $url->_expect('search', '%09gisle');

    # Let's test som other URL schemes
    $url = new URI::URL 'news:';
    $url->group("comp.lang.perl.misc");
    $url->_expect('as_string' => 'news:comp.lang.perl.misc');
    $url->article('<1234@a.sn.no>');
    $url->_expect('as_string' => 'news:1234@a.sn.no'); # "<" and ">" are gone
    # This one should be illegal
    eval { $url->article("no.perl"); };
    die "This one should really complain" unless $@;

#    $url = new URI::URL 'mailto:';
#    $url->user("aas");
#    $url->host("a.sn.no");
#    $url->_expect("as_string" => 'mailto:aas@a.sn.no');
#    $url->address('foo@bar');
#    $url->_expect("host" => 'bar');
#    $url->_expect("user" => 'foo');

#    $url = new URI::URL 'wais://host/database/wt/wpath';
#    $url->database('foo');
#    $url->_expect('as_string' => 'wais://host/foo/wt/wpath');
#    $url->wtype('bar');
#    $url->_expect('as_string' => 'wais://host/foo/bar/wpath');

    # Test crack method for various URLs
    my(@crack, $crack);
    @crack = URI::URL->new("http://host/path;param?query#frag")->crack;
    die "Cracked result should be 9 elements" unless @crack == 9;
    $crack = join("*", map { defined($_) ? $_ : "UNDEF" } @crack);
    print "Cracked result: $crack\n";
    die "Bad crack result" unless
      $crack eq "http*UNDEF*UNDEF*host*80*/path*param*query*frag";

    @crack = URI::URL->new("foo/bar", "ftp://aas\@ftp.sn.no/")->crack;
    die "Cracked result should be 9 elements" unless @crack == 9;
    $crack = join("*", map { defined($_) ? $_ : "UNDEF" } @crack);
    print "Cracked result: $crack\n";
#    die "Bad crack result" unless
#      $crack eq "ftp*UNDEF*UNDEF*UNDEF*21*foo/bar*UNDEF*UNDEF*UNDEF";

    @crack = URI::URL->new('ftp://u:p@host/q?path')->crack;
    die "Cracked result should be 9 elements" unless @crack == 9;
    $crack = join("*", map { defined($_) ? $_ : "UNDEF" } @crack);
    print "Cracked result: $crack\n";
    die "Bad crack result" unless
      $crack eq "ftp*u*p*host*21*/q?path*UNDEF*path*UNDEF";

    @crack = URI::URL->new("ftp://ftp.sn.no/pub")->crack;    # Test anon ftp
    die "Cracked result should be 9 elements" unless @crack == 9;
    die "No passwd in anonymous crack" unless $crack[2];
    $crack[2] = 'passwd';  # easier to test when we know what it is
    $crack = join("*", map { defined($_) ? $_ : "UNDEF" } @crack);
    print "Cracked result: $crack\n";
    die "Bad crack result" unless
      $crack eq "ftp*anonymous*passwd*ftp.sn.no*21*/pub*UNDEF*UNDEF*UNDEF";

    @crack = URI::URL->new('mailto:aas@sn.no')->crack;
    die "Cracked result should be 9 elements" unless @crack == 9;
    $crack = join("*", map { defined($_) ? $_ : "UNDEF" } @crack);
    print "Cracked result: $crack\n";
#    die "Bad crack result" unless
#      $crack eq "mailto*aas*UNDEF*sn.no*UNDEF*aas\@sn.no*UNDEF*UNDEF*UNDEF";

    @crack = URI::URL->new('news:comp.lang.perl.misc')->crack;
    die "Cracked result should be 9 elements" unless @crack == 9;
    $crack = join("*", map { defined($_) ? $_ : "UNDEF" } @crack);
    print "Cracked result: $crack\n";
    die "Bad crack result" unless
      $crack eq "news*UNDEF*UNDEF*UNDEF*119*comp.lang.perl.misc*UNDEF*UNDEF*UNDEF";
}

#
# netloc_test()
#
# Test automatic netloc synchronisation
#
sub netloc_test {
    print "netloc_test:\n";

    my $url = new URI::URL 'ftp://anonymous:p%61ss@håst:12345';
    $url->_expect('user', 'anonymous');
    $url->_expect('password', 'pass');
    $url->_expect('host', 'håst');
    $url->_expect('port', 12345);
    # Can't really know how netloc is represented since it is partially escaped
    #$url->_expect('netloc', 'anonymous:pass@hst:12345');
    $url->_expect('as_string' => 'ftp://anonymous:p%61ss@h%E5st:12345');

    # The '0' is sometimes tricky to get right
    $url->user(0);
    $url->password(0);
    $url->host(0);
    $url->port(0);
    $url->_expect('netloc' => '0:0@0:0');
    $url->host(undef);
    $url->_expect('netloc' => '0:0@:0');
    $url->host('h');
    $url->user(undef);
    $url->_expect('netloc' => ':0@h:0');
    $url->user('');
    $url->_expect('netloc' => ':0@h:0');
    $url->password('');
    $url->_expect('netloc' => ':@h:0');
    $url->user('foo');
    $url->_expect('netloc' => 'foo:@h:0');

    # Let's try a simple one
    $url->user('nemo');
    $url->password('p2');
    $url->host('hst2');
    $url->port(2);
    $url->_expect('netloc' => 'nemo:p2@hst2:2');

    $url->user(undef);
    $url->password(undef);
    $url->port(undef);
    $url->_expect('netloc' => 'hst2');
    $url->_expect('port' => '21');  # the default ftp port

    $url->port(21);
    $url->_expect('netloc' => 'hst2:21');

    # Let's try some reserved chars
    $url->user("@");
    $url->password(":-#-;-/-?");
    $url->_expect('as_string' => 'ftp://%40::-%23-;-%2F-%3F@hst2:21');

}

#
# port_test()
#
# Test port behaviour
#
sub port_test {
    print "port_test:\n";

    $url = URI::URL->new('http://foo/root/dir/');
    my $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq
	'http://foo/root/dir/';

    $url->port(8001);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 8001;
    die "Wrong string" unless $url->as_string eq
	'http://foo:8001/root/dir/';

    $url->port(80);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->canonical->as_string eq
	'http://foo/root/dir/';

    $url->port(8001);
    $url->port(undef);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq
	'http://foo/root/dir/';
}


#####################################################################
#
# escape_test()
#
# escaping functions

sub escape_test {
    print "escape_test:\n";

    # supply escaped URL
    $url = new URI::URL 'http://web/this%20has%20spaces';
    # check component is unescaped
    $url->_expect('path', '/this has spaces');

    # modify the unescaped form
    $url->path('this ALSO has spaces');
    # check whole url is escaped
    $url->_expect('as_string',
		  'http://web/this%20ALSO%20has%20spaces');

    $url = new URI::URL uri_escape('http://web/try %?#" those');
    $url->_expect('as_string',
		  'http%3A%2F%2Fweb%2Ftry%20%25%3F%23%22%20those');

    my $all = pack('C*',0..255);
    my $esc = uri_escape($all);
    my $new = uri_unescape($esc);
    die "uri_escape->uri_unescape mismatch" unless $all eq $new;

    $url->path($all);
    $url->_expect('full_path' => q(%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F%20!%22%23$%&'()*+,-./0123456789:;%3C=%3E%3F@ABCDEFGHIJKLMNOPQRSTUVWXYZ[%5C]%5E_%60abcdefghijklmnopqrstuvwxyz%7B%7C%7D~%7F%80%81%82%83%84%85%86%87%88%89%8A%8B%8C%8D%8E%8F%90%91%92%93%94%95%96%97%98%99%9A%9B%9C%9D%9E%9F%A0%A1%A2%A3%A4%A5%A6%A7%A8%A9%AA%AB%AC%AD%AE%AF%B0%B1%B2%B3%B4%B5%B6%B7%B8%B9%BA%BB%BC%BD%BE%BF%C0%C1%C2%C3%C4%C5%C6%C7%C8%C9%CA%CB%CC%CD%CE%CF%D0%D1%D2%D3%D4%D5%D6%D7%D8%D9%DA%DB%DC%DD%DE%DF%E0%E1%E2%E3%E4%E5%E6%E7%E8%E9%EA%EB%EC%ED%EE%EF%F0%F1%F2%F3%F4%F5%F6%F7%F8%F9%FA%FB%FC%FD%FE%FF));

    # test escaping uses uppercase (preferred by rfc1837)
    $url = new URI::URL 'file://h/';
    $url->path(chr(0x7F));
    $url->_expect('as_string', 'file://h/%7F');

    return;
    # reserved characters differ per scheme

    ## XXX is this '?' allowed to be unescaped
    $url = new URI::URL 'file://h/test?ing';
    $url->_expect('path', '/test?ing');

    $url = new URI::URL 'file://h/';
    $url->epath('question?mark');
    $url->_expect('as_string', 'file://h/question?mark');
    # XXX Why should this be any different???
    #     Perhaps we should not expect too much :-)
    $url->path('question?mark');
    $url->_expect('as_string', 'file://h/question%3Fmark');

    # See what happens when set different elements to this ugly sting
    my $reserved = ';/?:@&=#%';
    $url->path($reserved . "foo");
    $url->_expect('as_string', 'file://h/%3B/%3F%3A%40%26%3D%23%25foo');

    $url->scheme('http');
    $url->path('');
    $url->_expect('as_string', 'http://h/');
    $url->query($reserved);
    $url->params($reserved);
    $url->frag($reserved);
    $url->_expect('as_string', 'http://h/;%3B%2F%3F%3A%40&=%23%25?%3B%2F%3F%3A%40&=%23%25#;/?:@&=#%');

    $str = $url->as_string;
    $url = new URI::URL $str;
    die "URL changed" if $str ne $url->as_string;

    $url = new URI::URL 'ftp:foo';
    $url->user($reserved);
    $url->host($reserved);
    $url->_expect('as_string', 'ftp://%3B%2F%3F%3A%40%26%3D%23%25@%3B%2F%3F%3A%40%26%3D%23%25/foo');

}


#####################################################################
#
# newlocal_test()
#

sub newlocal_test {
    return 1 if $^O eq "MacOS";
    
    print "newlocal_test:\n";
    my $isMSWin32 = ($^O =~ /MSWin32/i);
    my $pwd = ($isMSWin32 ? 'cd' :
	      ($^O eq 'qnx' ? '/usr/bin/fullpath -t' :
              ($^O eq 'VMS' ? 'show default' :
              (-e '/bin/pwd' ? '/bin/pwd' : 'pwd'))));
    my $tmpdir = ($^O eq 'MSWin32' ? $ENV{TEMP} : '/tmp');
    if ( $^O eq 'qnx' ) {
	$tmpdir = `/usr/bin/fullpath -t $tmpdir`;
	chomp $tmpdir;
    }
    $tmpdir = '/sys$scratch' if $^O eq 'VMS';
    $tmpdir =~ tr|\\|/|;

    my $savedir = `$pwd`;     # we don't use Cwd.pm because we want to check
			      # that it get require'd correctly by URL.pm
    chomp $savedir;
    if ($^O eq 'VMS') {
        $savedir =~ s#^\s+##;
        $savedir = VMS::Filespec::unixpath($savedir);
        $savedir =~ s#/$##;
    }

    # cwd
    chdir($tmpdir) or die $!;
    my $dir = `$pwd`; $dir =~ tr|\\|/|;
    chomp $dir;
    if ($^O eq 'VMS') {
        $dir =~ s#^\s+##;
        $dir = VMS::Filespec::unixpath($dir);
        $dir =~ s#/$##;
    }
    $dir = uri_escape($dir, ':');
    $dir =~ s/^(\w)%3A/$1:/ if $isMSWin32;
    $url = newlocal URI::URL;
    my $ss = $isMSWin32 ? '//' : '';
    $url->_expect('as_string', URI::URL->new("file:$ss$dir/")->as_string);

    print "Local directory is ". $url->local_path . "\n";

    if ($^O ne 'VMS') {
    # absolute dir
    chdir('/') or die $!;
    $url = newlocal URI::URL '/usr/';
    $url->_expect('as_string', 'file:/usr/');

    # absolute file
    $url = newlocal URI::URL '/vmunix';
    $url->_expect('as_string', 'file:/vmunix');
    }

    # relative file
    chdir($tmpdir) or die $!;
    $dir = `$pwd`; $dir =~ tr|\\|/|;
    chomp $dir;
    if ($^O eq 'VMS') {
        $dir =~ s#^\s+##;
        $dir = VMS::Filespec::unixpath($dir);
        $dir =~ s#/$##;
    }
    $dir = uri_escape($dir, ':');
    $dir =~ s/^(\w)%3A/$1:/ if $isMSWin32;
    $url = newlocal URI::URL 'foo';
    $url->_expect('as_string', "file:$ss$dir/foo");

    # relative dir
    chdir($tmpdir) or die $!;
    $dir = `$pwd`; $dir =~ tr|\\|/|;
    chomp $dir;
    if ($^O eq 'VMS') {
        $dir =~ s#^\s+##;
        $dir = VMS::Filespec::unixpath($dir);
        $dir =~ s#/$##;
    }
    $dir = uri_escape($dir, ':');
    $dir =~ s/^(\w)%3A/$1:/ if $isMSWin32;
    $url = newlocal URI::URL 'bar/';
    $url->_expect('as_string', "file:$ss$dir/bar/");

    # 0
    if ($^O ne 'VMS') {
    chdir('/') or die $!;
    $dir = `$pwd`; $dir =~ tr|\\|/|;
        chomp $dir;
        $dir = uri_escape($dir, ':');
    $dir =~ s/^(\w)%3A/$1:/ if $isMSWin32;
    $url = newlocal URI::URL '0';
    $url->_expect('as_string', "file:$ss${dir}0");
    }

    # Test access methods for file URLs
    $url = new URI::URL 'file:/c:/dos';
    $url->_expect('dos_path', 'C:\\DOS');
    $url->_expect('unix_path', '/c:/dos');
    #$url->_expect('vms_path', '[C:]DOS');
    $url->_expect('mac_path',  'UNDEF');

    $url = new URI::URL 'file:/foo/bar';
    $url->_expect('unix_path', '/foo/bar');
    $url->_expect('mac_path', 'foo:bar');

    # Some edge cases
#    $url = new URI::URL 'file:';
#    $url->_expect('unix_path', '/');
    $url = new URI::URL 'file:/';
    $url->_expect('unix_path', '/');
    $url = new URI::URL 'file:.';
    $url->_expect('unix_path', '.');
    $url = new URI::URL 'file:./foo';
    $url->_expect('unix_path', './foo');
    $url = new URI::URL 'file:0';
    $url->_expect('unix_path', '0');
    $url = new URI::URL 'file:../../foo';
    $url->_expect('unix_path', '../../foo');
    $url = new URI::URL 'file:foo/../bar';
    $url->_expect('unix_path', 'foo/../bar');

    # Relative files
    $url = new URI::URL 'file:foo/b%61r/Note.txt';
    $url->_expect('unix_path', 'foo/bar/Note.txt');
    $url->_expect('mac_path', ':foo:bar:Note.txt');
    $url->_expect('dos_path', 'FOO\\BAR\\NOTE.TXT');
    #$url->_expect('vms_path', '[.FOO.BAR]NOTE.TXT');

    # The VMS path found in RFC 1738 (section 3.10)
    $url = new URI::URL 'file://vms.host.edu/disk$user/my/notes/note12345.txt';
#    $url->_expect('vms_path', 'DISK$USER:[MY.NOTES]NOTE12345.TXT');
#    $url->_expect('mac_path', 'disk$user:my:notes:note12345.txt');

    chdir($savedir) or die $!;
}


#####################################################################
#
# absolute_test()
#
sub absolute_test {

    print "Test relative/absolute URI::URL parsing:\n";

    # Tests from draft-ietf-uri-relative-url-06.txt
    # Copied verbatim from the draft, parsed below

    @URI::URL::g::ISA = qw(URI::URL::_generic); # for these tests

    my $base = 'http://a/b/c/d;p?q#f';

    $absolute_tests = <<EOM;
5.1.  Normal Examples

      g:h        = <URL:g:h>
      g          = <URL:http://a/b/c/g>
      ./g        = <URL:http://a/b/c/g>
      g/         = <URL:http://a/b/c/g/>
      /g         = <URL:http://a/g>
      //g        = <URL:http://g>
#      ?y         = <URL:http://a/b/c/d;p?y>
      g?y        = <URL:http://a/b/c/g?y>
      g?y/./x    = <URL:http://a/b/c/g?y/./x>
      #s         = <URL:http://a/b/c/d;p?q#s>
      g#s        = <URL:http://a/b/c/g#s>
      g#s/./x    = <URL:http://a/b/c/g#s/./x>
      g?y#s      = <URL:http://a/b/c/g?y#s>
 #     ;x         = <URL:http://a/b/c/d;x>
      g;x        = <URL:http://a/b/c/g;x>
      g;x?y#s    = <URL:http://a/b/c/g;x?y#s>
      .          = <URL:http://a/b/c/>
      ./         = <URL:http://a/b/c/>
      ..         = <URL:http://a/b/>
      ../        = <URL:http://a/b/>
      ../g       = <URL:http://a/b/g>
      ../..      = <URL:http://a/>
      ../../     = <URL:http://a/>
      ../../g    = <URL:http://a/g>

5.2.  Abnormal Examples

   Although the following abnormal examples are unlikely to occur
   in normal practice, all URL parsers should be capable of resolving
   them consistently.  Each example uses the same base as above.

   An empty reference resolves to the complete base URL:

      <>         = <URL:http://a/b/c/d;p?q#f>

   Parsers must be careful in handling the case where there are more
   relative path ".." segments than there are hierarchical levels in
   the base URL's path.  Note that the ".." syntax cannot be used to
   change the <net_loc> of a URL.

     ../../../g = <URL:http://a/../g>
     ../../../../g = <URL:http://a/../../g>

   Similarly, parsers must avoid treating "." and ".." as special
   when they are not complete components of a relative path.

      /./g       = <URL:http://a/./g>
      /../g      = <URL:http://a/../g>
      g.         = <URL:http://a/b/c/g.>
      .g         = <URL:http://a/b/c/.g>
      g..        = <URL:http://a/b/c/g..>
      ..g        = <URL:http://a/b/c/..g>

   Less likely are cases where the relative URL uses unnecessary or
   nonsensical forms of the "." and ".." complete path segments.

      ./../g     = <URL:http://a/b/g>
      ./g/.      = <URL:http://a/b/c/g/>
      g/./h      = <URL:http://a/b/c/g/h>
      g/../h     = <URL:http://a/b/c/h>

   Finally, some older parsers allow the scheme name to be present in
   a relative URL if it is the same as the base URL scheme.  This is
   considered to be a loophole in prior specifications of partial
   URLs [1] and should be avoided by future parsers.

      http:g     = <URL:http:g>
      http:      = <URL:http:>
EOM
    # convert text to list like
    # @absolute_tests = ( ['g:h' => 'g:h'], ...)

    for $line (split("\n", $absolute_tests)) {
	next unless $line =~ /^\s{6}/;
	if ($line =~ /^\s+(\S+)\s*=\s*<URL:([^>]*)>/) {
	    my($rel, $abs) = ($1, $2);
	    $rel = '' if $rel eq '<>';
	    push(@absolute_tests, [$rel, $abs]);
	}
	else {
	    warn "illegal line '$line'";
	}
    }

    # add some extra ones for good measure

    push(@absolute_tests, ['x/y//../z' => 'http://a/b/c/x/y/z'],
			  ['1'         => 'http://a/b/c/1'    ],
			  ['0'         => 'http://a/b/c/0'    ],
			  ['/0'        => 'http://a/0'        ],
#			  ['%2e/a'     => 'http://a/b/c/%2e/a'],  # %2e is '.'
#			  ['%2e%2e/a'  => 'http://a/b/c/%2e%2e/a'],
	);

    print "  Relative    +  Base  =>  Expected Absolute URL\n";
    print "================================================\n";
    for $test (@absolute_tests) {
	my($rel, $abs) = @$test;
	my $abs_url = new URI::URL $abs;
	my $abs_str = $abs_url->as_string;

	printf("  %-10s  +  $base  =>  %s\n", $rel, $abs);
	my $u   = new URI::URL $rel, $base;
	my $got = $u->abs;
	$got->_expect('as_string', $abs_str);
    }

    # bug found and fixed in 1.9 by "J.E. Fritz" <FRITZ@gems.vcu.edu>
    $base = new URI::URL 'http://host/directory/file';
    my $relative = new URI::URL 'file', $base;
    my $result = $relative->abs;

    my ($a, $b) = ($base->path, $result->path);
	die "'$a' and '$b' should be the same" unless $a eq $b;

    # Counter the expectation of least surprise,
    # section 6 of the draft says the URL should
    # be canonicalised, rather than making a simple
    # substitution of the last component.
    # Better doublecheck someone hasn't "fixed this bug" :-)
    $base = new URI::URL 'http://host/dir1/../dir2/file';
    $relative = new URI::URL 'file', $base;
    $result = $relative->abs;
    die 'URL not canonicalised' unless $result eq 'http://host/dir2/file';

    print "--------\n";
    # Test various other kinds of URLs and how they like to be absolutized
    for (["http://abc/", "news:45664545", "http://abc/"],
	 ["news:abc",    "http://abc/",   "news:abc"],
	 ["abc",         "file:/test?aas", "file:/abc"],
#	 ["gopher:",     "",               "gopher:"],
#	 ["?foo",        "http://abc/a",   "http://abc/a?foo"],
	 ["?foo",        "file:/abc",      "file:/?foo"],
	 ["#foo",        "http://abc/a",   "http://abc/a#foo"],
	 ["#foo",        "file:a",         "file:a#foo"],
	 ["#foo",        "file:/a",         "file:/a#foo"],
	 ["#foo",        "file:/a",         "file:/a#foo"],
	 ["#foo",        "file://localhost/a", "file://localhost/a#foo"],
	 ['123@sn.no',   "news:comp.lang.perl.misc", 'news:/123@sn.no'],
	 ['no.perl',     'news:123@sn.no',           'news:/no.perl'],
	 ['mailto:aas@a.sn.no', "http://www.sn.no/", 'mailto:aas@a.sn.no'],

	 # Test absolutizing with old behaviour.
	 ['http:foo',     'http://h/a/b',   'http://h/a/foo'],
	 ['http:/foo',    'http://h/a/b',   'http://h/foo'],
	 ['http:?foo',    'http://h/a/b',   'http://h/a/?foo'],
	 ['http:#foo',    'http://h/a/b',   'http://h/a/b#foo'],
	 ['http:?foo#bar','http://h/a/b',   'http://h/a/?foo#bar'],
	 ['file:/foo',    'http://h/a/b',   'file:/foo'],

	)
    {
	my($url, $base, $expected_abs) = @$_;
	my $rel = new URI::URL $url, $base;
	my $abs = $rel->abs($base, 1);
	printf("  %-12s+  $base  =>  %s\n", $rel, $abs);
	$abs->_expect('as_string', $expected_abs);
    }
    print "absolute test ok\n";

    # Test relative function
    for (
	 ["http://abc/a",   "http://abc",        "a"],
	 ["http://abc/a",   "http://abc/b",      "a"],
	 ["http://abc/a?q", "http://abc/b",      "a?q"],
	 ["http://abc/a;p", "http://abc/b",      "a;p"],
	 ["http://abc/a",   "http://abc/a/b/c/", "../../../a"],
         ["http://abc/a/",  "http://abc/a/",     "./"],
         ["http://abc/a#f", "http://abc/a",      "#f"],

	 ["file:/etc/motd", "file:/",            "etc/motd"],
	 ["file:/etc/motd", "file:/etc/passwd",  "motd"],
	 ["file:/etc/motd", "file:/etc/rc2.d/",  "../motd"],
	 ["file:/etc/motd", "file:/usr/lib/doc", "../../etc/motd"],
         ["file:",          "file:/etc/",        "../"],
         ["file:foo",       "file:/etc/",        "../foo"],

	 ["mailto:aas",     "http://abc",        "mailto:aas"],

	 # Nicolai Langfeldt's original example
	 ["http://www.math.uio.no/doc/mail/top.html",
	  "http://www.math.uio.no/doc/linux/", "../mail/top.html"],
        )
    {
	my($abs, $base, $expect) = @$_;
	printf "url('$abs', '$base')->rel eq '$expect'\n";
	my $rel = URI::URL->new($abs, $base)->rel;
	$rel->_expect('as_string', $expect);
    }
    print "relative test ok\n";
}


sub eq_test
{
    my $u1 = new URI::URL 'http://abc.com:80/~smith/home.html';
    my $u2 = new URI::URL 'http://ABC.com/%7Esmith/home.html';
    my $u3 = new URI::URL 'http://ABC.com:/%7esmith/home.html';

    # Test all permutations of these tree
    $u1->eq($u2) or die "1: $u1 ne $u2";
    $u1->eq($u3) or die "2: $u1 ne $u3";
    $u2->eq($u1) or die "3: $u2 ne $u1";
    $u2->eq($u3) or die "4: $u2 ne $u3";
    $u3->eq($u1) or die "5: $u3 ne $u1";
    $u3->eq($u2) or die "6: $u3 ne $u2";

    # Test empty path
    my $u4 = new URI::URL 'http://www.sn.no';
    $u4->eq("HTTP://WWW.SN.NO:80/") or die "7: $u4";
    $u4->eq("http://www.sn.no:81") and die "8: $u4";

    # Test mailto
#    my $u5 = new URI::URL 'mailto:AAS@SN.no';
#    $u5->eq('mailto:aas@sn.no') or die "9: $u5";

    # Test reserved char
    my $u6 = new URI::URL 'ftp://ftp/%2Fetc';
    $u6->eq("ftp://ftp/%2fetc") or die "10: $u6";
    $u6->eq("ftp://ftp://etc") and die "11: $u6";
}

