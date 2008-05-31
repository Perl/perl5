#!/usr/bin/perl -w

BEGIN {
    if ($ENV{PERL_CORE}) {
	# FIXME
	print "1..0 # Skip, needs fixing. Probably an -I issue\n";
	exit 0;
    }
}

use strict;
use lib 't/lib';
use Test::More tests => 1;
use File::Spec;
use App::Prove;

my $prove = App::Prove->new;

$prove->add_rc_file( File::Spec->catfile( 't', 'data', 'proverc' ) );

is_deeply $prove->{rc_opts},
  [ '--should', 'be', '--split', 'correctly', 'Can', 'quote things',
    'using single or', 'double quotes', '--this', 'is', 'OK?' ],
  'options parsed';

