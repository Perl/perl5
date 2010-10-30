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
plan(tests => 15);

use mro;

sub i {
 my @args = @_;
 @_
  = (
     join(" ", sort @{mro::get_isarev $args[0]}),
     join(" ", sort @args[1..$#args-1]),
     pop @args
    );
 goto &is;
}

$::TODO = "[perl #75176] isarev leeks (and onions)";

@Huskey::ISA = "Dog";
@Dog::ISA = "Canid";
@Wolf::ISA = "Canid";
@Some::Brand::Name::ISA = "Dog::Bone";
@Dog::Bone::ISA = "Treat";
@Free::Time::ISA = "Treat";
@MyCollar::ISA = "Dog::Collar::Leather";
@Dog::Collar::Leather::ISA = "Collar";
@Another::Collar::ISA = "Collar";
*Tike:: = *Dog::;
delete $::{"Dog::"};
i Canid=>qw[ Wolf Tike ],
 "deleting a stash elem updates isarev entries";
i Treat=>qw[ Free::Time Tike::Bone ],
 "deleting a nested stash elem updates isarev entries";
i Collar=>qw[ Another::Collar Tike::Collar::Leather ],
 "deleting a doubly nested stash elem updates isarev entries";

@Goat::ISA = "Ungulate";
@Goat::Dairy::ISA = "Goat";
@Goat::Dairy::Toggenburg::ISA = "Goat::Dairy";
@Weird::Thing::ISA = "g";
*g:: = *Goat::;
i Goat => qw[ Goat::Dairy Goat::Dairy::Toggenburg Weird::Thing ],
 "isarev includes subclasses of aliases";
delete $::{"g::"};
i Ungulate => qw[ Goat Goat::Dairy Goat::Dairy::Toggenburg ],
 "deleting an alias to a package updates isarev entries";
i"Goat" => qw[ Goat::Dairy Goat::Dairy::Toggenburg ],
 "deleting an alias to a package updates isarev entries of nested stashes";
i"Goat::Dairy" => qw[ Goat::Dairy::Toggenburg ],
 "deleting an stash alias updates isarev entries of doubly nested stashes";
i g => qw [ Weird::Thing ],
 "subclasses of the deleted alias become part of its isarev";

@Caprine::ISA = "Hoofed::Mammal";
@Caprine::Dairy::ISA = "Caprine";
@Caprine::Dairy::Oberhasli::ISA = "Caprine::Dairy";
@Whatever::ISA = "Caprine";
*Caprid:: = *Caprine::;
*Caprine:: = *Chevre::;
i"Hoofed::Mammal" => qw[ Caprid ],
 "replacing a stash updates isarev entries";
i Caprine => qw[ Whatever ],
 "replacing nested stashes updates isarev entries";

@Disease::Eye::ISA = "Disease";
@Disease::Eye::Infectious::ISA = "Disease::Eye";
@Keratoconjunctivitis::ISA = "Disease::Ophthalmic::Infectious";
*Disease::Ophthalmic:: = *Disease::Eye::;
*Disease::Ophthalmic:: = *some_random_new_symbol::;
i Disease => qw[ Disease::Eye ],
 "replacing an alias of a stash updates isarev entries";
i Caprine => qw[ Disease::Eye ],
 "replacing an alias of a stash containing another updates isarev entries";
i"some_random_new_symbol::Infectious" => qw[ Keratoconjunctivitis ],
 "replacing an alias updates isarev of stashes nested in the replacement";

# Globs ending with :: have autovivified stashes in them by default. We
# want one without a stash.
undef *Empty::;
@Null::ISA = "Empty";
@Null::Null::ISA = "Empty::Empty";
{package Zilch::Empty} # autovivify it
*Empty:: = *Zilch::;
i Zilch => qw[ Null ], "assigning to an empty spot updates isarev";
i"Zilch::Empty" => qw[ Null::Empty ],
 "assigning to an empty spot updates isarev of nested packages";
