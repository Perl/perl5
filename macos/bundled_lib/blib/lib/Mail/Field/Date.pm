# Mail::Field::Date
#
# Copyright (c) 1997 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# An example of a Mail::Field::* class

package Mail::Field::Date;

use strict;
use Mail::Field ();
use vars qw(@ISA $VERSION);
use Date::Format qw(time2str);
use Date::Parse qw(str2time);

@ISA = qw(Mail::Field);
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

bless([])->register('Date');

sub set
{
 my $self = shift;
 my $arg = @_ == 1 ? shift : { @_ };
 my $s;

 foreach $s (qw(Time TimeStr))
  {
   if(exists $arg->{$s}) { $self->{$s} = $arg->{$s} }
		    else { delete $self->{$s} }
  }

 $self;
}

sub parse
{
 my $self = shift;

 delete $self->{Time};
 $self->{TimeStr} = shift;
 $self;
}

sub time
{
 my $self = shift;

 if(@_)
  {
   delete $self->{TimeStr};
   return $self->{Time} = shift;
  }

 return $self->{Time}
	if exists $self->{Time};

 $self->{Time} = str2time($self->{TimeStr});
}

sub stringify
{
 my $self = shift;

 return $self->{TimeStr}
	if exists $self->{TimeStr};

 time2str("%a, %e %b %T %Y %z", $self->time);
}

sub reformat
{
 my $self = shift;
 $self->time($self->time);
 $self->stringify;
}

1;

