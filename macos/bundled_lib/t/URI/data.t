eval {
    require MIME::Base64;
};
if ($@) {
    print "1..0\n";
    print $@;
    exit;
}

print "1..21\n";

use URI;

$u = URI->new("data:,A%20brief%20note");
print "not " unless $u->scheme eq "data" && $u->opaque eq ",A%20brief%20note";
print "ok 1\n";

print "not " unless $u->media_type eq "text/plain;charset=US-ASCII" &&
	            $u->data eq "A brief note";
print "ok 2\n";

$old = $u->data("Får-i-kål er tingen!");
print "not " unless $old eq "A brief note" && $u eq "data:,F%E5r-i-k%E5l%20er%20tingen!";
print "ok 3\n";

$old = $u->media_type("text/plain;charset=iso-8859-1");
print "not " unless $old eq "text/plain;charset=US-ASCII" &&
                    $u eq "data:text/plain;charset=iso-8859-1,F%E5r-i-k%E5l%20er%20tingen!";
print "ok 4\n";


$u = URI->new("data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7");

print "not " unless $u->media_type eq "image/gif";
print "ok 5\n";

if ($ENV{DISPLAY} && $ENV{XV}) {
   open(XV, "| $ENV{XV} -") || die;
   print XV $u->data;
   close(XV);
}
print "not " unless length($u->data) == 273;
print "ok 6\n";

$u = URI->new("data:text/plain;charset=iso-8859-7,%be%fg%be");  # %fg
print "not " unless $u->data eq "\xBE%fg\xBE";
print "ok 7\n";

$u = URI->new("data:application/vnd-xxx-query,select_vcount,fcol_from_fieldtable/local");
print "not " unless $u->data eq "select_vcount,fcol_from_fieldtable/local";
print "ok 8\n";
$u->data("");
print "not " unless $u eq "data:application/vnd-xxx-query,";
print "ok 9\n";

$u->data("a,b"); $u->media_type(undef);
print "not " unless $u eq "data:,a,b";
print "ok 10\n";

# Test automatic selection of URI/BASE64 encoding
$u = URI->new("data:");
$u->data("");
print "not " unless $u eq "data:,";
print "ok 11\n";

$u->data(">");
print "not " unless $u eq "data:,%3E" && $u->data eq ">";
print "ok 12\n";

$u->data(">>>>>");
print "not " unless $u eq "data:,%3E%3E%3E%3E%3E";
print "ok 13\n";

$u->data(">>>>>>");
print "not " unless $u eq "data:;base64,Pj4+Pj4+";
print "ok 14\n";

$u->media_type("text/plain;foo=bar");
print "not " unless $u eq "data:text/plain;foo=bar;base64,Pj4+Pj4+";
print "ok 15\n";

$u->media_type("foo");
print "not " unless $u eq "data:foo;base64,Pj4+Pj4+";
print "ok 16\n";

$u->data(">" x 3000);
print "not " unless $u eq ("data:foo;base64," . ("Pj4+" x 1000)) &&
                    $u->data eq (">" x 3000);
print "ok 17\n";

$u->media_type(undef);
$u->data(undef);
print "not " unless $u eq "data:,";
print "ok 18\n";

$u = URI->new("data:foo");
print "not " unless $u->media_type("bar,båz") eq "foo";
print "ok 19\n";

print "not " unless $u->media_type eq "bar,båz";
print "ok 20\n";

$old = $u->data("new");
print "not " unless $old eq "" && $u eq "data:bar%2Cb%E5z,new";
print "ok 21\n";

