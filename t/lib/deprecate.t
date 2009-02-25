use strict;

BEGIN {
	chdir 't' if -d 't';
	chdir 'lib/deprecate' or die "Can't see lib/deprecate";
	@INC = qw(../../../lib
		lib/perl/arch
		lib/perl
		lib/site/arch
		lib/site
	);
}
use File::Copy ();
use File::Path ();
use Test::More tests => 10;

my %libdir = (
	privlibexp	=> 'lib/perl',
	sitelibexp	=> 'lib/site',
	archlibexp	=> 'lib/perl/arch',
	sitearchexp	=> 'lib/site/arch',
);

mkdir for 'lib', sort values %libdir;

our %tests = (
	privlibexp	=> 1,
	sitelibexp	=> 0,
	archlibexp	=> 1,
	sitearchexp	=> 0,
);

local %deprecate::Config = (%libdir);

for my $lib (sort keys %tests) {
    my $dir = $libdir{$lib};
    File::Copy::copy 'Deprecated.pm', "$dir/Deprecated.pm";

    my $warn;
    {   local $SIG{__WARN__} = sub { $warn .= $_[0]; };
        use warnings qw(deprecated);
#line 1001
	require Deprecated;
#line
    }
    if( $tests{$lib} ) {
        like($warn, qr/^Deprecated\s+will\s+be\s+removed\b/, "$lib - message");
        like($warn, qr/$0,?\s+line\s+1001\.?\n*$/, "$lib - location");
    }
    else {
	ok( !$warn, "$lib - no message" );
    }

    delete $INC{'Deprecated.pm'};
    unlink "$dir/Deprecated.pm";
}

for my $lib (sort keys %tests) {
    my $dir = $libdir{$lib};
    mkdir "$dir/Optionally";
    File::Copy::copy 'Optionally.pm', "$dir/Optionally/Deprecated.pm";

    my $warn;
    {   local $SIG{__WARN__} = sub { $warn .= $_[0]; };
        use warnings qw(deprecated);
	require Optionally::Deprecated;
    }
    if( $tests{$lib} ) {
        like($warn, qr/^Optionally::Deprecated\s+will\s+be\s+removed\b/,
		"$lib - use if - message");
    }
    else {
	ok( !$warn, "$lib - use if - no message" );
    }

    delete $INC{'Optionally/Deprecated.pm'};
    unlink "$dir/Optionally/Deprecated.pm";
}
# END { File::Path::rmtree 'lib' }
