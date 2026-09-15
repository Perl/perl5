use strict;
use warnings;
use Test::More;

use lib 'lib';
use RNG;

{
    package RNG::Bytes;

    sub new { bless { bytes => $_[1], calls => [] }, $_[0] }
    sub rand_bytes {
        my ($self, $length) = @_;
        push @{$self->{calls}}, $length;
        my $bytes = substr($self->{bytes}, 0, $length, '');
        $bytes .= "\0" x ($length - length($bytes));
        return $bytes;
    }
    sub srand { }
}

{
    my $rng = RNG::Bytes->new("\xff\x05");
    local ${^RNG} = $rng;
    is(RNG->uniform_int(10), 5,
       'uniform_int rejects an out-of-range candidate');
    is_deeply($rng->{calls}, [1, 1],
              'uniform_int requests only the bytes needed for the bound');
}

{
    my $rng = RNG::Bytes->new("\x00" x 20);
    local ${^RNG} = $rng;
    my $die = RNG->die(20);
    isa_ok($die, 'RNG::Die');
    is($die->pick, 1, 'pick is an alias for roll on a die');
    my $rolls = RNG->dice(3, $die)->rolls;
    isa_ok(RNG->dice(3, $die), 'RNG::Dice');
    is_deeply($rolls, [1, 1, 1], 'fair dice return individual rolls');
    is(RNG->dice(3, $die)->roll, 3, 'dice return the numeric sum');
    is(RNG->dice(3, $die)->pick, 3, 'pick is an alias for roll on dice');
}

{
    my $rng = RNG::Bytes->new("\0" x 20);
    local ${^RNG} = $rng;
    my $die = RNG->weighted_die({ 1 => 1, 2 => 0 });
    isa_ok($die->{alias}, 'RNG::AliasTable');
    is($die->roll, 1, 'zero-weight die faces are never selected');
    is(RNG->weighted_chooser({ red => 0, blue => 1 })->pick,
       'blue', 'weighted chooser selects the positive-weight value');
    is(RNG->weighted_chooser({ red => 0, blue => 1 })->roll,
       'blue', 'roll is an alias for pick on a chooser');
}

{
    my $rng = RNG::Bytes->new("\0" x 20);
    local ${^RNG} = $rng;
    my $left  = RNG->weighted_chooser({ b => 1, a => 1 });
    my $right = RNG->weighted_chooser({ a => 1, b => 1 });
    is($left->pick, $right->pick,
       'weighted table construction is independent of hash order');
}

{
    my $rng = RNG::Bytes->new("\0" x 8);
    local ${^RNG} = $rng;
    my $table = RNG::AliasTable->new({ red => 1, blue => 0 });
    isa_ok($table, 'RNG::AliasTable');
    is($table->roll, 'red', 'public alias tables support roll');
}

ok(!eval { RNG->uniform_int(0); 1 }, 'uniform_int rejects zero');
ok(!eval { RNG->die(0); 1 }, 'die rejects zero sides');
ok(!eval { RNG->weighted_die({ a => -1 }); 1 },
   'weighted die rejects negative weights');
ok(!eval { RNG->weighted_die({ a => 0, b => 0 }); 1 },
   'weighted die requires a positive weight');
ok(!eval { RNG->chooser([qw(a a)]); 1 },
   'chooser rejects duplicate values');

done_testing;
