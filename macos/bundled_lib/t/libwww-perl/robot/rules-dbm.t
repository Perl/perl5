
print "1..13\n";


use WWW::RobotRules::AnyDBM_File;

$file = "test-$$";

$r = new WWW::RobotRules::AnyDBM_File "myrobot/2.0", $file;

$r->parse("http://www.aas.no/robots.txt", "");

$r->visit("www.aas.no");

print "not " if $r->no_visits("www.aas.no") != 1;
print "ok 1\n";


$r->push_rules("www.sn.no", "/aas", "/per");
$r->push_rules("www.sn.no", "/god", "/old");

@r = $r->rules("www.sn.no");
print "Rules: @r\n";

print "not " if "@r" ne "/aas /per /god /old";
print "ok 2\n";

$r->clear_rules("per");
$r->clear_rules("www.sn.no");

@r = $r->rules("www.sn.no");
print "Rules: @r\n";

print "not " if "@r" ne "";
print "ok 3\n";

$r->visit("www.aas.no", time+10);
$r->visit("www.sn.no");

print "No visits: ", $r->no_visits("www.aas.no"), "\n";
print "Last visit: ", $r->last_visit("www.aas.no"), "\n";
print "Fresh until: ", $r->fresh_until("www.aas.no"), "\n";

print "not " if $r->no_visits("www.aas.no") != 2;
print "ok 4\n";

print "not " if abs($r->last_visit("www.sn.no") - time) > 2;
print "ok 5\n";

$r = undef;

# Try to reopen the database without a name specified
$r = new WWW::RobotRules::AnyDBM_File undef, $file;
$r->visit("www.aas.no");

print "not " if $r->no_visits("www.aas.no") != 3;
print "ok 6\n";

print "Agent-Name: ", $r->agent, "\n";
print "not " if $r->agent ne "myrobot";
print "ok 7\n";

$r = undef;

print "*** Dump of database ***\n";
tie(%cat, AnyDBM_File, $file, 0, 0644) or die "Can't tie: $!";
while (($key,$val) = each(%cat)) {
    print "$key\t$val\n";
}
print "******\n";

untie %cat;

# Try to open database with a different agent name
$r = new WWW::RobotRules::AnyDBM_File "MOMSpider/2.0", $file;

print "not " if $r->no_visits("www.sn.no");
print "ok 8\n";

# Try parsing
$r->parse("http://www.sn.no:8080/robots.txt", <<EOT, (time + 3));

User-Agent: *
Disallow: /

User-Agent: Momspider
Disallow: /foo
Disallow: /bar

EOT

@r = $r->rules("www.sn.no:8080");
print "not " if "@r" ne "/foo /bar";
print "ok 9\n";

print "not " if $r->allowed("http://www.sn.no") >= 0;
print "ok 10\n";

print "not " if $r->allowed("http://www.sn.no:8080/foo/gisle");
print "ok 11\n";

sleep(5);  # wait until file has expired
print "not " if $r->allowed("http://www.sn.no:8080/foo/gisle") >= 0;
print "ok 12\n";


$r = undef;

print "*** Dump of database ***\n";
tie(%cat, AnyDBM_File, $file, 0, 0644) or die "Can't tie: $!";
while (($key,$val) = each(%cat)) {
    print "$key\t$val\n";
}
print "******\n";

untie %cat;			# Otherwise the next line fails on DOSish

while (unlink("$file", "$file.pag", "$file.dir", "$file.db")) {}

# Try open a an emty database without specifying a name
eval { 
   $r = new WWW::RobotRules::AnyDBM_File undef, $file;
};
print $@;
print "not " unless $@;  # should fail
print "ok 13\n";

unlink "$file", "$file.pag", "$file.dir", "$file.db";
