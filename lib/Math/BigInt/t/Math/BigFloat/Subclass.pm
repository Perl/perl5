#!/usr/bin/perl -w

package Math::BigFloat::Subclass;

require 5.005_02;
use strict;

use Exporter;
use Math::BigFloat(1.23);
use vars qw($VERSION @ISA $PACKAGE
            $accuracy $precision $round_mode $div_scale);

@ISA = qw(Exporter Math::BigFloat);

$VERSION = 0.01;

# Globals
$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;

sub new
{
        my $proto  = shift;
        my $class  = ref($proto) || $proto;

        my $value       = shift || 0;   # Set to 0 if not provided
        my $decimal     = shift;
        my $radix       = 0;

        # Store the floating point value
        my $self = bless Math::BigFloat->new($value), $class;
        $self->{'_custom'} = 1; # make sure this never goes away
        return $self;
}

1;
