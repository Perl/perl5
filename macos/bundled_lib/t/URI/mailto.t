print "1..7\n";

use URI;

$u = URI->new('mailto:gisle@aas.no');

print "not " unless $u->to eq 'gisle@aas.no' &&
                    $u eq 'mailto:gisle@aas.no';
print "ok 1\n";

$old = $u->to('larry@wall.org');
print "not " unless $old eq 'gisle@aas.no' &&
                    $u->to eq 'larry@wall.org' &&
		    $u eq 'mailto:larry@wall.org';
print "ok 2\n";

$u->to("?/#");
print "not " unless $u->to eq "?/#" &&
                    $u eq 'mailto:%3F/%23';
print "ok 3\n";

@h = $u->headers;
print "not " unless @h == 2 && "@h" eq "to ?/#";
print "ok 4\n";

$u->headers(to      => 'gisle@aas.no',
            cc      => 'gisle@ActiveState.com,larry@wall.org',
            Subject => 'How do you do?',
	    garbage => '/;?#=&',
);

@h = $u->headers;
print "not " unless $u->to eq 'gisle@aas.no' &&
                    @h == 8 &&
                    "@h" eq 'to gisle@aas.no cc gisle@ActiveState.com,larry@wall.org Subject How do you do? garbage /;?#=&';
print "ok 5\n";

#print "$u\n";
print "not " unless $u eq 'mailto:gisle@aas.no?cc=gisle%40ActiveState.com%2Clarry%40wall.org&Subject=How+do+you+do%3F&garbage=%2F%3B%3F%23%3D%26';
print "ok 6\n";

$u = URI->new("mailto:");
$u->to("gisle");
print "not " unless $u eq 'mailto:gisle';
print "ok 7\n";
