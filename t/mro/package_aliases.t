#!./perl

BEGIN {
    unless (-d 'blib') {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
    require q(./test.pl);
}

use strict;
use warnings;
plan(tests => 10);

{
    package New;
    use strict;
    use warnings;

    package Old;
    use strict;
    use warnings;

    {
      no strict 'refs';
      *{'Old::'} = *{'New::'};
    }
}

ok (Old->isa (New::), 'Old inherits from New');
ok (New->isa (Old::), 'New inherits from Old');

isa_ok (bless ({}, Old::), New::, 'Old object');
isa_ok (bless ({}, New::), Old::, 'New object');


no warnings; # temporary, until bug #77358 is fixed

# Test that replacing a package by assigning to an existing glob
# invalidates the isa caches
{
 @Subclass::ISA = "Left";
 @Left::ISA = "TopLeft";

 sub TopLeft::speak { "Woof!" }
 sub TopRight::speak { "Bow-wow!" }

 my $thing = bless [], "Subclass";

 # mro_package_moved needs to know to skip non-globs
 $Right::{"gleck::"} = 3;

 @Right::ISA = 'TopRight';
 my $life_raft = $::{'Left::'};
 *Left:: = $::{'Right::'};

 is $thing->speak, 'Bow-wow!',
  'rearranging packages by assigning to a stash elem updates isa caches';

 undef $life_raft;
 is $thing->speak, 'Bow-wow!',
  'isa caches are up to date after the replaced stash is freed';
}

# Similar test, but with nested packages
{
 @Subclass::ISA = "Left::Side";
 @Left::Side::ISA = "TopLeft";

 sub TopLeft::speak { "Woof!" }
 sub TopRight::speak { "Bow-wow!" }

 my $thing = bless [], "Subclass";

 @Right::Side::ISA = 'TopRight';
 my $life_raft = $::{'Left::'};
 *Left:: = $::{'Right::'};

 is $thing->speak, 'Bow-wow!',
  'moving nested packages by assigning to a stash elem updates isa caches';

 undef $life_raft;
 is $thing->speak, 'Bow-wow!',
  'isa caches are up to date after the replaced nested stash is freed';
}

# Test that deleting stash elements containing
# subpackages also invalidates the isa cache.
# Maybe this does not belong in package_aliases.t, but it is closely
# related to the tests immediately preceding.
{
 @Pet::ISA = ("Cur", "Hound");
 @Cur::ISA = "Hylactete";

 sub Hylactete::speak { "Arff!" }
 sub Hound::speak { "Woof!" }

 my $pet = bless [], "Pet";

 my $life_raft = delete $::{'Cur::'};

 is $pet->speak, 'Woof!',
  'deleting a stash from its parent stash invalidates the isa caches';

 undef $life_raft;
 is $pet->speak, 'Woof!',
  'the deleted stash is gone completely when freed';
}
