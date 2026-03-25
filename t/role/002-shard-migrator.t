#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

## -----------------------------------------------------------------------------

role Locator {
    method get_new_shard_for_key;
    method get_old_shard_for_key;
}

role Control {
    method is_migration_enabled;
    method enable_migration;
    method disable_migration;
}

role Strategy {
    method migrate;
}

## -----------------------------------------------------------------------------

role Locator::Modulo :does(Locator) {
    field $old_shard_count :param;
    field $new_shard_count :param;

    method get_new_shard_for_key ($key) { $key % $new_shard_count }
    method get_old_shard_for_key ($key) { $key % $old_shard_count }
}

role Control::ENV :does(Control) {
    field $env :param;

    method is_migration_enabled { !! $env->{ENABLED} }

    method enable_migration  { $env->{ENABLED} = true  }
    method disable_migration { $env->{ENABLED} = false }
}

class ShardMigrator :does(Locator::Modulo, Control::ENV, Strategy) {
    field $shards :param :reader;

    method migrate ($key) {
        my $old = $self->get_old_shard_for_key($key);
        my $new = $self->get_new_shard_for_key($key);
        $shards->[$new]->{$key} = delete $shards->[$old]->{$key};
    }

    method fetch ($key) {
        $self->migrate($key) if $self->is_migration_enabled;
        return $shards->[$self->get_new_shard_for_key($key)]->{$key};
    }
}


# ...

my @shards = ( +{}, +{}, +{}, +{} );
for (1 .. 100) {
    $shards[$_ % 2]->{ $_ } = "KEY: $_";
}

my $migrator = ShardMigrator->new(
    shards          => \@shards,
    old_shard_count => 2,
    new_shard_count => 4,
    env => +{
        ENABLED => true
    },
);

isa_ok($migrator, 'ShardMigrator');
ok($migrator->DOES($_), "... does ${_}") foreach qw[
    Locator
    Locator::Modulo
    Control
    Control::ENV
    Strategy
];

is((scalar keys $shards[0]->%*), 50, '... balanced shards');
is((scalar keys $shards[1]->%*), 50, '... balanced shards');
is((scalar keys $shards[2]->%*), 0, '... empty shards');
is((scalar keys $shards[3]->%*), 0, '... empty shards');

my @migrated = map { $migrator->fetch($_) } 1 .. 100;

is(scalar(@migrated), 100, '... got the expected output');

is((scalar keys $shards[0]->%*), 25, '... balanced shards');
is((scalar keys $shards[1]->%*), 25, '... balanced shards');
is((scalar keys $shards[2]->%*), 25, '... balanced shards');
is((scalar keys $shards[3]->%*), 25, '... balanced shards');

done_testing;
