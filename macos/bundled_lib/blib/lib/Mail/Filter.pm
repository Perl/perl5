# Mail::Filter.pm
#
# Copyright (c) 1997 Graham Barr <gbarr@pobox.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::Filter;

use Carp;
use strict;
use vars qw($VERSION);

$VERSION = "1.01";

sub new {
    my $self = shift;
    
    bless {
	filters => [ @_ ]
    }, $self;
}

sub add {
    my $self = shift;
    push(@{$self->{'filters'}}, @_);
}

sub _filter {
    my $self = shift;
    my $mail = shift;
    my $sub;

    foreach $sub (@{$self->{'filters'}}) {
	if(ref($sub) eq "CODE") {
	    $mail = $sub->($self,$mail);
	}
	elsif(!ref($sub)) {
	    $mail = $self->$sub($mail);
	}
	else {
	   carp "Cannot call filter '$sub', ignored";
	}
	last unless ref($mail);
    }
    # the specification indicates that the result of operations on $mail 
    # should be returned by this function
    return $mail;
}

sub filter {
    my $self = shift;
    my $obj = shift;
    
    if($obj->isa('Mail::Folder')) {
	$self->{'folder'} = $obj;
	my $m;
	foreach $m ($obj->message_list) {
	    my $mail = $obj->get_message($m) || next;
	    $self->{'msgnum'} = $m;
	    _filter($self,$mail);
	}
	delete $self->{'folder'};
	delete $self->{'msgnum'};
    }
    elsif($obj->isa('Mail::Internet')) {
	return _filter($self,$obj);
    }
    else {
	carp "Cannot process '$obj'";
	return undef;
    }
}

sub folder {
    my $self = shift;
    exists $self->{'folder'}
	? $self->{'folder'}
	: undef;
}

sub msgnum {
    my $self = shift;
    exists $self->{'msgnum'}
	? $self->{'msgnum'}
	: undef;
}


1;

__END__

=head1 NAME

Mail::Filter - Filter mail through multiple subroutines

=head1 SYNOPSIS

    use Mail::Filter;
    
    $filter = new Mail::Filter( \&filter1, \&filter2 );
    
    $mail = new Mail::Internet( [<>] );
    $mail = $filter->filter($mail);
    
    $folder = new Mail::Folder( .... );
    $filter->filter($folder);

=head1 DESCRIPTION

C<Mail::Filter> provides an interface to filtering Email through multiple
subroutines.

C<Mail::Filter> filters mail by calling each filter subroutine in turn. Each
filter subroutine is called with two arguments, the first is the filter
object and the second is the mail or folder object being filtered.

The result from each filter sub is passed to the next filter as the mail
object. If a filter subroutine returns undef, then C<Mail::Filter> will abort
and return immediately.

The function returns the result from the last subroutine to operate on the 
mail object.  

=head1 CONSTRUCTOR

=over 4

=item new ( [ FILTER [, ... ]])

Create a new C<Mail::Filter> object with the given filter subroutines. Each
filter may be either a code reference or the name of a method to call
on the <Mail::Filter> object.

=back

=head1 METHODS

=over 4

=item add ( FILTER [, FILTER ...] )

Add the given filters to the end of the fliter list.

=item filter ( MAIL-OBJECT | MAIL-FOLDER )

If the first argument is a C<Mail::Internet> object, then this object will
be passed through the filter list. If the first argument is a C<Mail::Folder>
object, then each message in turn will be passed through the filter list.

=item folder

If the C<filter> method is called with a C<Mail::Folder> object, then the
filter subroutines may call this method to obtain the folder object that is
being processed.

=item msgnum

If the C<filter> method is called with a C<Mail::Folder> object, then the
filter subroutines may call this method to obtain the message number
of the message that is being processed.

=back

=head1 SEE ALSO

L<Mail::Internet>
L<Mail::Folder>

=head1 AUTHOR

Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1997 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut


