package Mail::Field::AddrList;

=head1 NAME 

Mail::Field::AddrList - object representation of e-mail address lists

=head1 DESCRIPTION

I<Don't use this class directly!> Instead ask Mail::Field for new
instances based on the field name!

=head1 SYNOPSIS

  use Mail::Field::AddrList;

  $to = Mail::Field->new('To');
  $from = Mail::Field->new('From', 'poe@daimi.aau.dk (Peter Orbaek)');
  
  $from->create('foo@bar.com' => 'Mr. Foo', poe => 'Peter');
  $from->parse('foo@bar.com (Mr Foo), Peter Orbaek <poe>');

  # make a RFC822 header string
  print $from->stringify(),"\n";

  # extract e-mail addresses and names
  @addresses = $from->addresses();
  @names = $from->names();

  # adjoin a new address to the list
  $from->set_address('foo@bar.com', 'Mr. Foo');

=head1 NOTES

Defines parsing and formatting according to RFC822, of the following fields:
To, From, Cc, Reply-To and Sender.

=head1 AUTHOR

Peter Orbaek <poe@cit.dk> 26-Feb-97
Modified by Graham Barr <gbarr@pobox.com>

=cut

use strict;
use vars qw(@ISA $VERSION);
use Mail::Field ();
use Carp;
use Mail::Address;

@ISA = qw(Mail::Field);
$VERSION = '1.0';

# install header interpretation, see Mail::Field
INIT: {
    my $x = bless([]);

    $x->register('To');
    $x->register('From');
    $x->register('Cc');
    $x->register('Reply-To');
    $x->register('Sender');
}

sub create {
    my ($self, %arg) = @_;  # (email => name, email => realname,...)
    my($e,$n);
    $self->{AddrList} = {};

    $self->{AddrList}{$e} = Mail::Address->new($n,$e)
	while(($e,$n) = each %arg);

    $self;
}

sub parse {
    my ($self, $string) = @_;
    my ($a,$email,$name);

    foreach $a (Mail::Address->parse($string)) {
	my $e = $a->address;
	$self->{AddrList}{$e} = $a;
    }
    $self;
}

sub stringify {
    my $self = shift;
    my ($x, $email, $name);

    join(", ", map { $_->format } values %{$self->{AddrList}});
}

sub addresses {
    keys %{shift->{AddrList}};
}

sub names {
    map { $_->name } values %{shift->{AddrList}};
}

sub set_address {
    my ($self, $email, $name) = @_;
    $self->{AddrList}{$email} = Mail::Address->new($name, $email);
    $self;
}

1;
