#!perl

print "1..15\n";

use URI;

$url = URI->new("ldap://host/dn=base?cn,sn?sub?objectClass=*");

print "not " unless $url->host eq "host";
print "ok 1\n";

print "not " unless $url->dn eq "dn=base";
print "ok 2\n";

print "not " unless join("-",$url->attributes) eq "cn-sn";
print "ok 3\n";

print "not " unless $url->scope eq "sub";
print "ok 4\n";

print "not " unless $url->filter eq "objectClass=*";
print "ok 5\n";

$uri = URI->new("ldap:");
$uri->dn("o=University of Michigan,c=US");

print "not " unless "$uri" eq "ldap:o=University%20of%20Michigan,c=US" &&
    $uri->dn eq "o=University of Michigan,c=US";
print "ok 6\n";

$uri->host("ldap.itd.umich.edu");
print "not " unless $uri->as_string eq "ldap://ldap.itd.umich.edu/o=University%20of%20Michigan,c=US";
print "ok 7\n";

# check defaults
print "not " unless $uri->_scope  eq "" &&
                    $uri->scope   eq "base" &&
                    $uri->_filter eq "" &&
                    $uri->filter  eq "(objectClass=*)";
print "ok 8\n";

# attribute
$uri->attributes("postalAddress");
print "not " unless $uri eq "ldap://ldap.itd.umich.edu/o=University%20of%20Michigan,c=US?postalAddress";
print "ok 9\n";

# does attribute escapeing work as it should
$uri->attributes($uri->attributes, "foo", ",", "*", "?", "#", "\0");

print "not " unless $uri->attributes eq "postalAddress,foo,%2C,*,%3F,%23,%00" &&
                    join("-", $uri->attributes) eq "postalAddress-foo-,-*-?-#-\0";
print "ok 10\n";
$uri->attributes("");

$uri->scope("sub?#");
print "not " unless $uri->query eq "?sub%3F%23" &&
                    $uri->scope eq "sub?#";
print "ok 11\n";
$uri->scope("");

$uri->filter("f=?,#");
print "not " unless $uri->query eq "??f=%3F,%23" &&
                    $uri->filter eq "f=?,#";

$uri->filter("(int=\\00\\00\\00\\04)");
print "not " unless $uri->query eq "??(int=%5C00%5C00%5C00%5C04)";
print "ok 12\n";


print "ok 13\n";
$uri->filter("");

$uri->extensions("!bindname" => "cn=Manager,co=Foo");
my %ext = $uri->extensions;

print "not " unless $uri->query eq "???!bindname=cn=Manager%2Cco=Foo" &&
                    keys %ext == 1 &&
                    $ext{"!bindname"} eq "cn=Manager,co=Foo";
print "ok 14\n";

$uri = URI->new("ldap://LDAP-HOST:389/o=University%20of%20Michigan,c=US?postalAddress?base?ObjectClass=*?FOO=Bar,bindname=CN%3DManager%CO%3dFoo");

print "not " unless $uri->canonical eq "ldap://ldap-host/o=University%20of%20Michigan,c=US?postaladdress???foo=Bar,bindname=CN=Manager%CO=Foo";
print "ok 15\n";

print "$uri\n";
print $uri->canonical, "\n";
