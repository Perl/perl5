# Test option setting methods

print "1..5\n";

use strict;
use HTML::Parser ();

my $p = HTML::Parser->new(api_version => 3,
			  xml_mode => 1);
my $old;

$old = $p->boolean_attribute_value("foo");
print "not " if defined $old;
print "ok 1\n";

$old = $p->boolean_attribute_value();
print "not " unless $old eq "foo";
print "ok 2\n";

$old = $p->boolean_attribute_value(undef);
print "not " unless $old eq "foo" && !defined($p->boolean_attribute_value);
print "ok 3\n";

print "not " unless $p->xml_mode(0) && !$p->xml_mode;
print "ok 4\n";

my $seen_buggy_comment_warning;
$SIG{__WARN__} =
    sub {
	local $_ = shift;
	$seen_buggy_comment_warning++
	    if /^netscape_buggy_comment\(\) is deprecated/;
        print;
    };

print "not " if $p->strict_comment(1) ||
                !$p->strict_comment   ||
                $p->netscape_buggy_comment ||
                !$seen_buggy_comment_warning;
print "ok 5\n";
