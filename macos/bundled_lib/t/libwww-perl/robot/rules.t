#!/local/bin/perl

=head1 NAME

robot-rules.t

=head1 DESCRIPTION

Test a number of different A</robots.txt> files against a number
of different User-agents.

=cut

require WWW::RobotRules;
use Carp;
use strict;

print "1..32\n"; # for Test::Harness

# We test a number of different /robots.txt files,
#

my $content1 = <<EOM;
# http://foo/robots.txt
User-agent: *
Disallow: /private
Disallow: http://foo/also_private

User-agent: MOMspider
Disallow:
EOM

my $content2 = <<EOM;
# http://foo/robots.txt
User-agent: MOMspider
 # comment which should be ignored
Disallow: /private
EOM

my $content3 = <<EOM;
# http://foo/robots.txt
EOM

my $content4 = <<EOM;
# http://foo/robots.txt
User-agent: *
Disallow: /private
Disallow: mailto:foo

User-agent: MOMspider
Disallow: /this

User-agent: Another
Disallow: /that


User-agent: SvartEnke1
Disallow: http://fOO
Disallow: http://bar

User-Agent: SvartEnke2
Disallow: ftp://foo
Disallow: http://foo:8080/
Disallow: http://bar/
EOM

# and a number of different robots:

my @tests1 = (
	   [$content1, 'MOMspider' =>
	    1 => 'http://foo/private' => 1,
	    2 => 'http://foo/also_private' => 1,
	   ],

	   [$content1, 'Wubble' =>
	    3 => 'http://foo/private' => 0,
	    4 => 'http://foo/also_private' => 0,
	    5 => 'http://foo/other' => 1,
	   ],

	   [$content2, 'MOMspider' =>
	    6 => 'http://foo/private' => 0,
	    7 => 'http://foo/other' => 1,
	   ],

	   [$content2, 'Wubble' =>
	    8  => 'http://foo/private' => 1,
	    9  => 'http://foo/also_private' => 1,
	    10 => 'http://foo/other' => 1,
	   ],

	   [$content3, 'MOMspider' =>
	    11 => 'http://foo/private' => 1,
	    12 => 'http://foo/other' => 1,
	   ],

	   [$content3, 'Wubble' =>
	    13 => 'http://foo/private' => 1,
	    14 => 'http://foo/other' => 1,
	   ],

	   [$content4, 'MOMspider' =>
	    15 => 'http://foo/private' => 1,
	    16 => 'http://foo/this' => 0,
	    17 => 'http://foo/that' => 1,
	   ],

	   [$content4, 'Another' =>
	    18 => 'http://foo/private' => 1,
	    19 => 'http://foo/this' => 1,
	    20 => 'http://foo/that' => 0,
	   ],

	   [$content4, 'Wubble' =>
	    21 => 'http://foo/private' => 0,
	    22 => 'http://foo/this' => 1,
	    23 => 'http://foo/that' => 1,
	   ],

	   [$content4, 'Another/1.0' =>
	    24 => 'http://foo/private' => 1,
	    25 => 'http://foo/this' => 1,
	    26 => 'http://foo/that' => 0,
	   ],

	   [$content4, "SvartEnke1" =>
	    27 => "http://foo/" => 0,
	    28 => "http://foo/this" => 0,
	    29 => "http://bar/" => 1,
	   ],

	   [$content4, "SvartEnke2" =>
	    30 => "http://foo/" => 1,
	    31 => "http://foo/this" => 1,
	    32 => "http://bar/" => 1,
	   ],

	   # when adding tests, remember to increase
	   # the maximum at the top

	  );

my $t;

for $t (@tests1) {
    my ($content, $ua) = splice(@$t, 0, 2);

    my $robotsrules = new WWW::RobotRules($ua);
    $robotsrules->parse('http://foo/robots.txt', $content);

    my ($num, $path, $expected);
    while(($num, $path, $expected) = splice(@$t, 0, 3)) {
	my $allowed = $robotsrules->allowed($path);
	$allowed = 1 if $allowed;
	if($allowed != $expected) {
	    $robotsrules->dump;
	    confess "Test Failed: $ua => $path ($allowed != $expected)";
	}
	print "ok $num\n";
    }
}
