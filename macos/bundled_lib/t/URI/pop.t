print "1..8\n";

use URI;

$u = URI->new('pop://aas@pop.sn.no');

print "not " unless $u->user eq "aas" &&
                    !defined($u->auth) &&
	            $u->host eq "pop.sn.no" &&
                    $u->port == 110 && 
		    $u eq 'pop://aas@pop.sn.no';
print "ok 1\n";

$u->auth("+APOP");
print "not " unless $u->auth eq "+APOP" &&
                    $u eq 'pop://aas;AUTH=+APOP@pop.sn.no';
print "ok 2\n";

$u->user("gisle");
print "not " unless $u->user eq "gisle" &&
	            $u eq 'pop://gisle;AUTH=+APOP@pop.sn.no';
print "ok 3\n";

$u->port(4000);
print "not " unless $u eq 'pop://gisle;AUTH=+APOP@pop.sn.no:4000';
print "ok 4\n";

$u = URI->new("pop:");
$u->host("pop.sn.no");
$u->user("aas");
$u->auth("*");
print "not " unless $u eq 'pop://aas;AUTH=*@pop.sn.no';
print "ok 5\n";

$u->auth(undef);
print "not " unless $u eq 'pop://aas@pop.sn.no';
print "ok 6\n";

$u->user(undef);
print "not " unless $u eq 'pop://pop.sn.no';
print "ok 7\n";

# Try some funny characters too
$u->user('får;k@l');
print "not " unless $u->user eq 'får;k@l' &&
                    $u eq 'pop://f%E5r%3Bk%40l@pop.sn.no';
print "ok 8\n";
