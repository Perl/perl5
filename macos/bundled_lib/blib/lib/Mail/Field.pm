# Mail::Field.pm
#
# Copyright (c) 1995-2000 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::Field;

# $Id: //depot/MailTools/Mail/Field.pm#7 $

use Carp;
use strict;
use vars qw($AUTOLOAD $VERSION);

$VERSION = "1.08";

unless(defined &UNIVERSAL::can) {
    *UNIVERSAL::can = sub {
	my($obj,$meth) = @_;
	my $pkg = ref($obj) || $obj;
	my @pkg = ($pkg);
	my %done;
	while(@pkg) {
            $pkg = shift @pkg;
            next if exists $done{$pkg};
            $done{$pkg} = 1;

	    no strict 'refs';

            unshift @pkg,@{$pkg . "::ISA"}
        	if(@{$pkg . "::ISA"});
            return \&{$pkg . "::" . $meth}
        	if defined(&{$pkg . "::" . $meth});
	}
	undef;
    }
}

sub _header_pkg_name
{
 my($header) = lc shift;

 $header =~ s/((\b|_)\w)/\U$1/gio;

 if (length($header) > 8)
  {
   my @header = split /[-_]+/, $header;
   my $chars = int((7 + @header) / @header) || 1;
   $header = substr(join('', map { substr($_,0,$chars) } @header),0,8);
  }
 else
  {
   $header =~ s/[-_]+//go;
  }

 'Mail::Field::' . $header;
}

##
## Use the import method to load the sub-classes
##

sub _require_dir
{
 my($pkg,$dir,$dir_sep) = @_;

 if(opendir(DIR,$dir))
  {
   my @inc =  ();
   my $f;

   foreach $f (readdir(DIR))
    {
     next
	unless $f =~ /^([\w\-]+)/;

     my $p = $1;
     my $n = $dir . $dir_sep . $p;

     if(-d $n )
      {
       _require_dir( $pkg . "::" . $f, $n, $dir_sep);
      }
     else
      {
       $p =~ s/-/_/go;
       eval "require ${pkg}::$p"
      }
    }
   closedir(DIR);
  }
}

sub import
{
 my $pkg = shift;

 if(@_)
  {
   local $_;
   map { 
        eval "require " . _header_pkg_name($_) || die $@;
       } @_;
  }
 else
  {
   my($f,$dir,$dir_sep);
   foreach $f (keys %INC)
    {
     if($f =~ /^Mail(\W)Field\W/i)
      {
       $dir_sep = $1;
       $dir = ($INC{$f} =~ /(.*Mail\W+Field)/i)[0] . $dir_sep;
       last;
      }
    }
   _require_dir('Mail::Field', $dir, $dir_sep);
  }
}


##
## register a header class, this creates a new method in Mail::Field
## which will call new on that class
##

sub register
{
 my $self = shift;
 my $method = lc shift;
 my $pkg = shift || ref($self) || $self;

 $method =~ tr/-/_/;

 $pkg = _header_pkg_name($method)
	if($pkg eq "Mail::Field");

 croak "Re-register of $method"
	if Mail::Field->can($method);

 no strict 'refs';
 *{$method} = sub {
	shift;
	unless ($pkg->can('stringify')) {
	    eval "require $pkg" || die $@;
	}
	$pkg->_build(@_);
 };

}

##
## the *real* constructor
## if called with one argument then the `parse' method will be called
## otherwise the `create' method is called
##

sub _build
{
 my $type = shift;
 my $self = bless {}, $type;

 @_ == 1 ? $self->parse(@_)
	 : $self->create(@_);
}

sub new
{
 my $self  = shift; # ignored
 my $field = lc shift;

 $field =~ tr/-/_/;
 
 $self->$field(@_);
}

##
## A default create method. This allows us to do
## $s = Mail::Field->new('Subject', Text => "joe");
## $s = Mail::Field->new('Subject', "joe");
##

sub create
{
 my $self = shift;
 my %arg = @_;

 $self = bless {}, $self
	unless ref($self);

 %$self = ();

 $self->set(\%arg);
}

##
## A default create method. This allows us to do
## $s = Mail::Field->new('Subject');
##

sub parse
{
 my $self = shift;
 my $type = ref($self) || $self;

 croak "$type: Cannot parse";
}

##
## either get the text, or parse a new one
##

sub text
{
 my $self = shift;
 @_ ? $self->parse(@_)
    : $self->stringify;
}

##
## Return the tag (in the correct case) for this item
##

sub tag
{
 my $self = shift;
 my $tag = ref($self) || $self;

 $tag =~ s/.*:://o;
 $tag =~ s/_/-/og;
 $tag =~ s/\b([a-z]+)/\L\u$1/gio;
 $tag =~ s/\b([b-df-hj-np-tv-z]+)\b/\U$1/gio;

 $tag;
}

##
## a constructor
## create a new object by extracting from a Mail::Header object
##

sub extract
{
 my $self = shift;

 my $tag  = shift;
 my $head = shift;

 my $method = lc $tag;
 $method =~ tr/-/_/;

 my $text;

 if(@_ == 0 && wantarray)
  {
   my @ret = ();

   foreach $text ($head->get($tag))
    {
     chomp($text);

     push(@ret, $self->$method($text));
    }

   return @ret;
  }

 my $idx  = shift || 0;

 $text = $head->get($tag,$idx) or
	return undef;

 chomp($text);

 $self->$method($text);
}

##
## Autoload sub-classes, or, if the .pm file cannot be found, create a dummy
## sub-class based on Mail::Field::Generic
##

sub AUTOLOAD
{
 my $method = $AUTOLOAD;

 $method =~ s/.*:://o;

 croak "Undefined subroutine &$AUTOLOAD called"
	unless $method =~ /^[^A-Z\x00-\x1f\x80-\xff :]+$/o;

 my $pkg = _header_pkg_name($method);

 unless(eval "require " . $pkg)
  {
   my $tag = $method;

   $tag =~ s/_/-/og;
   $tag =~ s/\b([a-z]+)/\L\u$1/gio;
   $tag =~ s/\b([b-df-hj-np-tv-z]+)\b/\U$1/gio;

   no strict;

   @{$pkg . "::ISA"} = qw(Mail::Field::Generic);
   *{$pkg . "::tag"} = sub { $tag };
  }

  $pkg->register($method)
	unless(Mail::Field->can($method));

 goto &$AUTOLOAD;
}

##
## prevent the calling of AUTOLOAD for DESTROY :-)
##

sub DESTROY {}

##
## A generic package for those not defined in thier own package. This is
## fine for fields like Subject, X-Mailer etc. where the field holds only
## a string of no particular importance/format.
##

package Mail::Field::Generic;

use Carp;
use vars qw(@ISA);

@ISA = qw(Mail::Field);

sub create
{
 my $self = shift;
 my %arg = @_;
 my $text = delete $arg{Text} || "";

 croak "Unknown options " . join(",", keys %arg)
	if %arg;

 $self->{Text} = $text;

 $self;
}

sub parse
{
 my $self = shift;

 $self->{Text} = shift || "";
 $self;
}

sub stringify
{
 my $self = shift;
 $self->{Text};
}

1;

__END__

=head1 NAME

Mail::Field - Base class for manipulation of mail header fields

=head1 SYNOPSIS

    use Mail::Field;
    
    $field = Mail::Field->new('Subject', 'some subject text');
    print $field->tag,": ",$field->stringify,"\n";

    $field = Mail::Field->subject('some subject text');

=head1 DESCRIPTION

C<Mail::Field> is a base class for packages that create and manipulate
fields from Email (and MIME) headers. Each different field will have its
own sub-class, defining its own interface.

This document describes the minimum interface that each sub-class should
provide, and also guidlines on how the field specific interface should be
defined. 

=head1 CONSTRUCTOR

Mail::Field, and it's sub-classes define several methods which return
new objects. These can all be termed to be constructors.

=over 4

=item new ( TAG [, STRING | OPTIONS ] )

The new constructor will create an object in the class which defines
the field specified by the tag argument.

After creation of the object :-

If the tag argument is followed by a single string then the C<parse> method
will be called with this string.

If the tag argument is followed by more than one arguments then the C<create>
method will be called with these arguments.

=item extract ( TAG, HEAD [, INDEX ] )

This constuctor takes as arguments the tag name, a C<Mail::Head> object
and optionally an index.

If the index argument is given then C<extract> will retrieve the given tag
from the C<Mail::Head> object and create a new C<Mail::Field> based object.
I<undef> will be returned in the field does not exist.

If the index argument is not given the the result depends on the context
in which C<extract> is called. If called in a scalar context the result
will be as if C<extract> was called with an index value of zero. If called
in an array context then all tags will be retrieved and a list of
C<Mail::Field> objects will be returned.

=item combine ( FIELD_LIST )

This constructor takes as arguments a list of C<Mail::Field> objects, which
should all be of the same sub-class, and creates a new object in that same
class.

This constructor is nor defined in C<Mail::Field> as there is no generic
way to combine the various field types. Each sub-class should define
its own combine constructor, if combining is possible/allowed.

=back

=head1 METHODS

=over 4

=item parse

=item set

=item tag

=item stringify

=back

=head1 SUB-CLASS PACKAGE NAMES

All sub-classes should be called Mail::Field::I<name> where I<name> is
derived from the tag using these rules.

=over 4

=item *

Consider a tag as being made up of elements separated by '-'

=item *

Convert all characters to lowercase except the first in each element, which
should be uppercase.

=item *

I<name> is then created from these elements by using the first
N characters from each element.

=item *

N is calculated by using the formula :-

    int((7 + #elements) / #elements)

=item *

I<name> is then limited to a maximum of 8 characters, keeping the first 8
characters

=back

For an example of this take a look at the definition of the 
C<_header_pkg_name> subroutine in C<Mail::Field>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 SEE ALSO

L<MIME::*>s

=head1 CREDITS

Eryq <eryq@rhine.gsfc.nasa.gov> - for all the help in defining this package
so that Mail::* and MIME::* can be integrated together.

=head1 COPYRIGHT

Copyright (c) 1995-2000 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut


