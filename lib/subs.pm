package subs;

require 5.000;

$ExportLevel = 0;

sub import {
    my $callpack = caller;
    my $pack = shift;
    my @imports = @_;
    foreach $sym (@imports) {
	*{"${callpack}::$sym"} = \&{"${callpack}::$sym"};
    }
};

1;
