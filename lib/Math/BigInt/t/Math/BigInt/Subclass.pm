#!/usr/bin/perl -w

package Math::BigInt::Subclass;

require 5.005_02;
use strict;

use Exporter;
use Math::BigInt(1.45);
use vars qw($VERSION @ISA $PACKAGE @EXPORT_OK
            $accuracy $precision $round_mode $div_scale);

@ISA = qw(Exporter Math::BigInt);
@EXPORT_OK = qw(bgcd);

$VERSION = 0.01;

# Globals
$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;

sub new
{
        my $proto  = shift;
        my $class  = ref($proto) || $proto;

        my $value       = shift;	# no || 0 here!
        my $decimal     = shift;
        my $radix       = 0;

        # Store the floating point value
        my $self = bless Math::BigInt->new($value), $class;
        $self->{'_custom'} = 1; # make sure this never goes away
        return $self;
}

sub bgcd
  {
  Math::BigInt::bgcd(@_);
  }

sub blcm
  {
  Math::BigInt::blcm(@_);
  }

sub import
  {
  my $self = shift;
#  Math::BigInt->import(@_);
  $self->SUPER::import(@_);                     # need it for subclasses
  #$self->export_to_level(1,$self,@_);           # need this ?
  }

1;
