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
plan(tests => 3);

use mro;

sub i {
 @_ = @_;
 $_[0] = "@{mro::get_isarev $_[0]}";
 $_[1] = "@{$_[1]}";
 goto &is;
}

$::TODO = "[perl #75176] isarev leeks (and onions)";

@Huskey::ISA = "Dog";
@Dog::ISA = "Canid";
@Some::Brand::Name::ISA = "Dog::Bone";
@Dog::Bone::ISA = "Treat";
@MyCollar::ISA = "Dog::Collar::Leather";
@Dog::Collar::Leather::ISA = "Collar";
delete $::{"Dog::"};
i Canid=>[], "deleting a stash elem removes isarev entries";
i Treat=>[], "deleting a nested stash elem removes isarev entries";
i Collar=>[], "deleting a doubly nested stash elem removes isarev entries";
