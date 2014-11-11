use strict;
use warnings;
use Test::Stream;
use Test::More;
use Test::Stream::Tester;

events_are(
    intercept {
        my $id = 0;
        Test::Stream->shared->munge(sub {
            my ($stream, $e) = @_;
            return unless $e->isa('Test::Stream::Event::Ok');
            return if defined $e->name;
            $e->set_name( 'flubber: ' . $id++ );
        });

        ok( 1, "Keep the name" );
        ok( 1 );
        ok( 1, "Already named" );
        ok( 1 );
    },
    check {
        event ok => { bool => 1, name => "Keep the name" };
        event ok => { bool => 1, name => "flubber: 0" };
        event ok => { bool => 1, name => "Already named" };
        event ok => { bool => 1, name => "flubber: 1" };
    }
);

done_testing;
