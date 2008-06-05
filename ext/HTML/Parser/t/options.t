# Test option setting methods

use Test::More tests => 10;

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3,
			  xml_mode => 1);
my $old;

$old = $p->boolean_attribute_value("foo");
ok(!defined $old);

$old = $p->boolean_attribute_value();
is($old, "foo");

$old = $p->boolean_attribute_value(undef);
is($old, "foo");
ok(!defined($p->boolean_attribute_value));

ok($p->xml_mode(0));
ok(!$p->xml_mode);

my $seen_buggy_comment_warning;
$SIG{__WARN__} =
    sub {
	local $_ = shift;
	$seen_buggy_comment_warning++
	    if /^netscape_buggy_comment\(\) is deprecated/;
    };

ok(!$p->strict_comment(1));
ok($p->strict_comment);
ok(!$p->netscape_buggy_comment);
ok($seen_buggy_comment_warning);
