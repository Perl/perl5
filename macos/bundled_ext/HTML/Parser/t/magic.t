# Check that the magic signature at the top of struct p_state works and that we
# catch modifications to _hparser_xs_state gracefully

print "1..5\n";

use HTML::Parser;

$p = HTML::Parser->new(api_version => 3);

$p->xml_mode(1);

# We should not be able to simply modify this stuff
eval {
    ${$p->{_hparser_xs_state}} += 4;
};
print "not " unless $@ && $@ =~ /^Modification of a read-only value attempted/;
print "ok 1\n";


my $x = delete $p->{_hparser_xs_state};

eval {
    $p->xml_mode(1);
};
print "not " unless $@ && $@ =~ /^Can't find '_hparser_xs_state'/;
print "ok 2\n";

$p->{_hparser_xs_state} = \($$x + 16);

eval {
    $p->xml_mode(1);
};
print "not " unless $@ && $@ =~ /^Bad signature in parser state object/;
print "ok 3\n";

$p->{_hparser_xs_state} = 33;
eval {
    $p->xml_mode(1);
};
print "not " unless $@ && $@ =~ /^_hparser_xs_state element is not a reference/;
print "ok 4\n";

$p->{_hparser_xs_state} = $x;

print "not " unless $p->xml_mode(0);
print "ok 5\n";
