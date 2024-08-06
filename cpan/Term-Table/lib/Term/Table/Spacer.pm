package Term::Table::Spacer;
use strict;
use warnings;

our $VERSION = '0.020';

sub new { bless {}, $_[0] }

sub width { 1 }

sub sanitize  { }
sub mark_tail { }
sub reset     { }

1;
