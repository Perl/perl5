
package Mail::Send;

# $Id: //depot/MailTools/Mail/Send.pm#6 $

use strict;
use Carp;
use vars qw($VERSION);
require Mail::Mailer;

$VERSION = "1.09";

sub Version { $VERSION }

sub new {
    my $pkg = shift;
    my %attr = @_;
    my($key, $value);
    my $me = bless {}, $pkg;
    while( ($key, $value) = each %attr ) {
	$key = lc($key);
	$me->$key($value);
    }
    $me;
}

sub set {
    my($me, $hdr, @values) = @_;
    $me->{$hdr} = [ @values ] if @values;
    @{$me->{$hdr} || []};	# return new (or original) values
}

sub add {
    my($me, $hdr, @values) = @_;
    $me->{$hdr} = [] unless $me->{$hdr};
    push(@{$me->{$hdr}}, @values);
}

sub delete {
    my($me, $hdr) = @_;
    delete $me->{$hdr};
}

sub to		{ my $me=shift; $me->set('To', @_); }
sub cc		{ my $me=shift; $me->set('Cc', @_); }
sub bcc		{ my $me=shift; $me->set('Bcc', @_); }
sub subject	{ my $me=shift; $me->set('Subject', join (' ', @_)); }


sub open {
    my $me = shift;
    Mail::Mailer->new(@_)->open($me);
}

1;

__END__

=head1 NAME

Mail::Send - Simple electronic mail interface

=head1 SYNOPSIS

    require Mail::Send;

    $msg = new Mail::Send;

    $msg = new Mail::Send Subject=>'example subject', To=>'timbo';

    $msg->to('user@host');
    $msg->subject('example subject');
    $msg->cc('user@host');
    $msg->bcc('someone@else');

    $msg->set($header, @values);
    $msg->add($header, @values);
    $msg->delete($header);

    # Launch mailer and set headers. The filehandle returned
    # by open() is an instance of the Mail::Mailer class.

    $fh = $msg->open;

    print $fh "Body of message";

    $fh->close;         # complete the message and send it

    $fh->cancel;        # not yet implemented

=head1 DESCRIPTION

=head1 SEE ALSO

Mail::Mailer

=head1 AUTHORS

Maintained by Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

Original code written by Tim Bunce E<lt>F<Tim.Bunce@ig.co.uk>E<gt>,
with a kick start from Graham Barr E<lt>F<gbarr@pobox.com>E<gt>. With
contributions by Gerard Hickey E<lt>F<hickey@ctron.com>E<gt>

For support please contact comp.lang.perl.misc or Graham Barr
E<lt>F<gbarr@pobox.com>E<gt>

=cut


