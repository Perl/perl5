#
# $Id: Encoder.pm,v 0.1 2002/04/08 02:35:10 dankogai Exp $
#
package Encoder;
use strict;
our $VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d"  x $#r, @r };

require Exporter;
our @ISA = qw(Exporter);
# Public, encouraged API is exported by default
our @EXPORT = qw (
  encoder
);

our $AUTOLOAD;
our $DEBUG = 0;
use Encode qw(encode decode find_encoding from_to);
use Carp;

sub new{
    my ($class, $data, $encname) = @_;
    $encname ||= 'utf8';
    my $obj = find_encoding($encname) 
	or croak __PACKAGE__, ": unknown encoding: $encname";
    my $self = {
		data     => $data,
		encoding => $obj->name,
	       };
    bless $self => $class;
}

sub encoder{ shift->new(@_) }

sub data{
    my ($self, $data) = shift;
    defined $data and $self->{data} = $data;
    return $self;
}

sub encoding{
    my ($self, $encname) = @_;
    if ($encname){
	my $obj = find_encoding($encname) 
	    or confess __PACKAGE__, ": unknown encoding: $encname";
	$self->{encoding} = $obj->name;
    }
    $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
	or confess "$self is not an object";
    my $myname = $AUTOLOAD;
    $myname =~ s/.*://;   # strip fully-qualified portion
    my $obj = find_encoding($myname) 
	    or confess __PACKAGE__, ": unknown encoding: $myname";
    $DEBUG and warn $self->{encoding}, " => ", $obj->name;
    from_to($self->{data}, $self->{encoding}, $obj->name, 1);
    $self->{encoding} = $obj->name;
    return $self;
}

use overload 
    q("") => sub { $_[0]->{data} },
    q(0+) => sub { use bytes (); bytes::length($_[0]->{data}) },
    fallback => 1,
    ;

1;
__END__

=head1 NAME

Encode::Encoder -- Object Oriented Encoder

=head1 SYNOPSIS
       
  use Encode::Encoder;
  # Encode::encode("ISO-8859-1", $data); 
  Encoder->new($data)->iso_8859_1; # OOP way
  # shortcut
  encoder($data)->iso_8859_1;
  # you can stack them!
  encoder($data)->iso_8859_1->base64; # provided base64() is defined
  # stringified
  print encoder($utf8)->latin1     # prints the string in latin1
  # numified
  encoder("\x{abcd}\x{ef}g") == 6; # true. bytes::length($data)

=head1 ABSTRACT

B<Encode::Encoder> allows you to use Encode via OOP style.  This is
not only more intuitive than functional approach, but also handier
when you want to stack encodings.  Suppose you want your UTF-8 string
converted to Latin1 then Base64, you can simply say

  my $base64 = encoder($utf8)->latin1->base64;

instead of

  my $latin1 = encode("latin1", $utf8);

or lazier and convolted

  my $base64 = encode_base64(encode("latin1", $utf8));

=head1 Description

Here is how to use this module.

=over 4

=item *

There are at least two instance variable stored in hash reference,
{data} and {encoding}.

=item *

When there is no method, it takes the method name as the name of
encoding and encode instance I<data> with I<encoding>.  If successful,
instance I<encoding> is set accordingly.

=item * 

This module is desined to work with L<Encode::Encoding>.
To make the Base64 transcorder example above really work, you should
write a module like this.

  package Encode::Base64;
  use base 'Encode::Encoding';
  __PACKAGE->Define('base64');
  use MIME::Base64;
  sub encode{ 
    my ($obj, $data) = @_; 
    return encode_base64($data);
  }
  sub decode{
    my ($obj, $data) = @_; 
    return decode_base64($data);
  }
  1;
  __END__

And your caller module should be like this;

  use Encode::Encoder;
  use Encode::Base64;
  # and be creative.

=head2 operator overloading

This module overloads two operators, stringify ("") and numify (0+).

Stringify dumps the data therein.

Numify returns the number of bytes therein.

They come in handy when you want to print or find the size of data.

=back

=head2 Predefined Methods

This module predefines the methods below;

=over 4

=item $e = Encode::Encoder-E<gt>new([$data, $encoding]);

returns the encoder object.  Its data is initialized with $data if
there, and its encoding is set to $encoding if there.

=item encoder()

is an alias of Encode::Encoder-E<gt>new().  This one is exported for
convenience.

=item $e-E<gt>data($data)

sets instance data to $data.

=item $e-E<gt>encoding($encoding)

sets instance encoding to $encoding

=back

=head1 SEE ALSO

L<Encode>
L<Encode::Encoding>

=cut
