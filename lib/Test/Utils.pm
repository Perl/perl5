package Test::Utils;

use 5.004;

use strict;
require Exporter;
use vars qw($VERSION @EXPORT @EXPORT_TAGS @ISA);

$VERSION = '0.02';

@ISA = qw(Exporter);
@EXPORT = qw( my_print print );
                


# Special print function to guard against $\ and -l munging.
sub my_print (*@) {
    my($fh, @args) = @_;

    local $\;
    print $fh @args;
}

sub print { die "DON'T USE PRINT!  Use _print instead" }

1;
