use strict;
use warnings;
use Test::More;
use utf8;

my $ps;
sub run_with_lib {
    my @idnlib = @_;
    my %require = (
	'URI::_idna' => 0,
	'Net::LibIDN' => 0,
	'Net::IDN::Encode' => 0,
	map { $_ => 1 } @idnlib,
    );

    my %block;
    my $can_idn;
    while ( my ($lib,$load) = each %require ) {
	if ( $load ) {
	    $can_idn = eval "require $lib";
	} else {
	    $lib =~s{::}{/}g;
	    $block{"$lib.pm"} = 1;
	}
    }
    unshift @INC, sub {
	return sub {0} if $block{$_[1]};
	return;
    };

    require IO::Socket::SSL::PublicSuffix;

    plan tests => 79;


    # all one-level, but co.uk two-level
    $ps = IO::Socket::SSL::PublicSuffix->from_string("*\nco.uk");
    ok($ps,"create two-level");
    minimal_private_suffix('com','','com');
    minimal_private_suffix('bar.com','','bar.com');
    minimal_private_suffix('www.bar.com','www','bar.com');
    minimal_private_suffix('www.foo.bar.com','www.foo','bar.com');
    minimal_private_suffix('uk','','uk');
    minimal_private_suffix('co.uk','','co.uk');
    minimal_private_suffix('www.co.uk','','www.co.uk');
    minimal_private_suffix('www.bar.co.uk','www','bar.co.uk');
    minimal_private_suffix('www.foo.bar.co.uk','www.foo','bar.co.uk');
    minimal_private_suffix('bl.uk','','bl.uk');
    minimal_private_suffix('www.bl.uk','www','bl.uk');
    minimal_private_suffix('www.bar.bl.uk','www.bar','bl.uk');
    minimal_private_suffix('www.foo.bar.bl.uk','www.foo.bar','bl.uk');


    $ps = IO::Socket::SSL::PublicSuffix->default(min_suffix => 0);
    # taken from Mozilla::PublicSuffix 0.1.18 t/01-psuffix.t ------
    # Obviously invalid input:
    is public_suffix(undef), undef;
    is public_suffix(''), undef;
    is public_suffix([]), undef;

    # Mixed case:
    is public_suffix('COM'), 'com';
    is public_suffix('example.COM'), 'com';
    is public_suffix('WwW.example.COM'), 'com';
    is public_suffix('123bar.com'), 'com';
    is public_suffix('foo.123bar.com'), 'com';

    if(0) {
	# behaves different
	# - we return '' instead of undef if unknown extension
	# - we return com with *.com
	# Leading dot:
	is public_suffix('.com'), undef;
	is public_suffix('.example'), undef;
	is public_suffix('.example.com'), undef;
	is public_suffix('.example.example'), undef;

	# Unlisted TLD:
	is public_suffix('example'), undef;
	is public_suffix('example.example'), undef;
	is public_suffix('b.example.example'), undef;
	is public_suffix('a.b.example.example'), undef;

	# Listed, but non-Internet, TLD:
	is public_suffix('local'), undef;
	is public_suffix('example.local'), undef;
	is public_suffix('b.example.local'), undef;
	is public_suffix('a.b.example.local'), undef;
    } else {
	# Leading dot:
	is public_suffix('.com'), 'com';
	is public_suffix('.example'), '';
	is public_suffix('.example.com'), 'com';
	is public_suffix('.example.example'), '';

	# Unlisted TLD:
	is public_suffix('example'), '';
	is public_suffix('example.example'), '';
	is public_suffix('b.example.example'), '';
	is public_suffix('a.b.example.example'), '';

	# Listed, but non-Internet, TLD:
	is public_suffix('local'), '';
	is public_suffix('example.local'), '';
	is public_suffix('b.example.local'), '';
	is public_suffix('a.b.example.local'), '';
    }

    # TLD with only one rule:
    is public_suffix('biz'), 'biz';
    is public_suffix('domain.biz'), 'biz';
    is public_suffix('b.domain.biz'), 'biz';
    is public_suffix('a.b.domain.biz'), 'biz';

    # TLD with some two-level rules:
    is public_suffix('com'), 'com';
    is public_suffix('example.com'), 'com';
    is public_suffix('b.example.com'), 'com';
    is public_suffix('a.b.example.com'), 'com';

    # uk.com is not in the ICANN part of the list
    if(0) {
	is public_suffix('uk.com'), 'uk.com';
	is public_suffix('example.uk.com'), 'uk.com';
	is public_suffix('b.example.uk.com'), 'uk.com';
	is public_suffix('a.b.example.uk.com'), 'uk.com';
    }
    is public_suffix('test.ac'), 'ac';

    # TLD with only one (wildcard) rule:
    if(0) {
	# we return '' not undef
	is public_suffix('bd'), undef;
    } else {
	is public_suffix('bd'), '';
    }
    is public_suffix('c.bd'), 'c.bd';
    is public_suffix('b.c.bd'), 'c.bd';
    is public_suffix('a.b.c.bd'), 'c.bd';

    # More complex suffixes:
    is public_suffix('jp'), 'jp';
    is public_suffix('test.jp'), 'jp';
    is public_suffix('www.test.jp'), 'jp';
    is public_suffix('ac.jp'), 'ac.jp';
    is public_suffix('test.ac.jp'), 'ac.jp';
    is public_suffix('www.test.ac.jp'), 'ac.jp';
    is public_suffix('kyoto.jp'), 'kyoto.jp';
    is public_suffix('c.kyoto.jp'), 'kyoto.jp';
    is public_suffix('b.c.kyoto.jp'), 'kyoto.jp';
    is public_suffix('a.b.c.kyoto.jp'), 'kyoto.jp';
    is public_suffix('ayabe.kyoto.jp'), 'ayabe.kyoto.jp';
    is public_suffix('test.kobe.jp'), 'test.kobe.jp';     # Wildcard rule.
    is public_suffix('www.test.kobe.jp'), 'test.kobe.jp'; # Wildcard rule.
    is public_suffix('city.kobe.jp'), 'kobe.jp';          # Exception rule.
    is public_suffix('www.city.kobe.jp'), 'kobe.jp';      # Identity rule.

    # TLD with a wildcard rule and exceptions:
    if(0) {
	# we return '' not undef
	is public_suffix('ck'), undef;
    } else {
	is public_suffix('ck'), '';
    }
    is public_suffix('test.ck'), 'test.ck';
    is public_suffix('b.test.ck'), 'test.ck';
    is public_suffix('a.b.test.ck'), 'test.ck';
    is public_suffix('www.ck'), 'ck';
    is public_suffix('www.www.ck'), 'ck';

    # US K12:
    is public_suffix('us'), 'us';
    is public_suffix('test.us'), 'us';
    is public_suffix('www.test.us'), 'us';
    is public_suffix('ak.us'), 'ak.us';
    is public_suffix('test.ak.us'), 'ak.us';
    is public_suffix('www.test.ak.us'), 'ak.us';
    is public_suffix('k12.ak.us'), 'k12.ak.us';
    is public_suffix('test.k12.ak.us'), 'k12.ak.us';
    is public_suffix('www.test.k12.ak.us'), 'k12.ak.us';

    # Domains and gTLDs with characters outside the ASCII range:
    SKIP: {
	if ( $can_idn ) {
	    is public_suffix('test.敎育.hk'), '敎育.hk';
	    is public_suffix('ਭਾਰਤ.ਭਾਰਤ'), 'ਭਾਰਤ';
	} else {
	    skip "no IDN support with @idnlib",2
	}
    }
}


sub minimal_private_suffix {
    my $host = shift;
    if ( @_ == 2 ) {
	my ($rest,$suffix) = @_;
	my @r = $ps->public_suffix($host,+1);
	if ( $r[0] eq $rest and $r[1] eq $suffix ) {
	    pass("$host -> $rest + $suffix");
	} else {
	    fail("$host -> $r[0]($rest) + $r[1]($suffix)");
	}
    } elsif ( @_ == 1 ) {
	my ($expect_suffix) = @_;
	my $got_suffix = $ps->public_suffix($host,+1);
	is( $got_suffix,$expect_suffix, "$host -> suffix=$expect_suffix");
    } else {
	die "@_";
    }
}

sub public_suffix {
    my $host = shift;
    my $suffix = $ps->public_suffix($host);
    return $suffix;
}

1;


