use strict;
use warnings;

use Test::More;

my @classes = ('Pod::Perldoc', map { "Pod::Perldoc::$_" } qw(
    BaseTo       ToChecker    ToNroff      ToRtf
    GetOptsOO    ToMan        ToPod        ToText       ToXml
    ToANSI       ToTerm
) );

if( eval { require Tk; require Tk::Pod; 1 } ) { push @classes, 'Pod::Perldoc::ToTk' }
else {
	diag "Skip testing Pod::Perldoc::ToTk because there's no Tk";
	}

plan tests => scalar @classes;

foreach my $class ( @classes ) {
	require_ok( $class );
	my $version = do { no strict 'refs'; ${ '$' . $class . '::VERSION' } };
	diag( "$class $version" ) if defined $version
	}
