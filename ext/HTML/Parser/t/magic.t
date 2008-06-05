# Check that the magic signature at the top of struct p_state works and that we
# catch modifications to _hparser_xs_state gracefully

use Test::More tests => 5;

use HTML::Parser;

$p = HTML::Parser->new(api_version => 3);

$p->xml_mode(1);

# We should not be able to simply modify this stuff
eval {
    ${$p->{_hparser_xs_state}} += 4;
};
like($@, qr/^Modification of a read-only value attempted/);


my $x = delete $p->{_hparser_xs_state};

eval {
    $p->xml_mode(1);
};
like($@, qr/^Can't find '_hparser_xs_state'/);

$p->{_hparser_xs_state} = \($$x + 16);

eval {
    $p->xml_mode(1);
};
like($@, $] >= 5.008 ? qr/^Lost parser state magic/ : qr/^Bad signature in parser state object/);

$p->{_hparser_xs_state} = 33;
eval {
    $p->xml_mode(1);
};
like($@,  qr/^_hparser_xs_state element is not a reference/);

$p->{_hparser_xs_state} = $x;

ok($p->xml_mode(0));
