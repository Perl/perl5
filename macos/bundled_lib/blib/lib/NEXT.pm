package NEXT;
use Carp;
use strict;

sub ancestors
{
	my @inlist = @_;
	my @outlist = ();
	while (@inlist) {
		push @outlist, shift @inlist;
		no strict 'refs';
		unshift @inlist, @{"$outlist[-1]::ISA"};
	}
	return @outlist;
}

sub AUTOLOAD
{
	my ($self) = @_;
	my $caller = (caller(1))[3]; 
	my $wanted = $NEXT::AUTOLOAD || 'NEXT::AUTOLOAD';
	undef $NEXT::AUTOLOAD;
	my ($caller_class, $caller_method) = $caller =~ m{(.*)::(.*)}g;
	my ($wanted_class, $wanted_method) = $wanted =~ m{(.*)::(.*)}g;
	croak "Can't call $wanted from $caller"
		unless $caller_method eq $wanted_method;

	local $NEXT::NEXT{$self,$wanted_method} =
	      $NEXT::NEXT{$self,$wanted_method};

	unless (@{$NEXT::NEXT{$self,$wanted_method}||[]}) {
		my @forebears = ancestors ref $self;
		while (@forebears) {
			last if shift @forebears eq $caller_class
		}
		no strict 'refs';
		@{$NEXT::NEXT{$self,$wanted_method}} = 
			map { *{"${_}::$caller_method"}{CODE}||() } @forebears
				unless $wanted_method eq 'AUTOLOAD';
		@{$NEXT::NEXT{$self,$wanted_method}} = 
			map { (*{"${_}::AUTOLOAD"}{CODE}) ?
						"${_}::AUTOLOAD" : () } @forebears
				unless @{$NEXT::NEXT{$self,$wanted_method}||[]};
	}
	my $call_method = shift @{$NEXT::NEXT{$self,$wanted_method}};
	return unless defined $call_method;
	if (ref $call_method eq 'CODE') {
		return shift()->$call_method(@_)
	}
	else {	# AN AUTOLOAD
		no strict 'refs';
		${$call_method} = $caller_method eq 'AUTOLOAD' && ${"${caller_class}::AUTOLOAD"} || $wanted;
		return $call_method->(@_);
	}
}

1;

__END__

=head1 NAME

NEXT.pm - Provide a pseudo-class NEXT that allows method redispatch


=head1 SYNOPSIS

	use NEXT;

	package A;
	sub A::method   { print "$_[0]: A method\n";   $_[0]->NEXT::method() }
	sub A::DESTROY  { print "$_[0]: A dtor\n";     $_[0]->NEXT::DESTROY() }

	package B;
	use base qw( A );
	sub B::AUTOLOAD { print "$_[0]: B AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
	sub B::DESTROY  { print "$_[0]: B dtor\n";     $_[0]->NEXT::DESTROY() }

	package C;
	sub C::method   { print "$_[0]: C method\n";   $_[0]->NEXT::method() }
	sub C::AUTOLOAD { print "$_[0]: C AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
	sub C::DESTROY  { print "$_[0]: C dtor\n";     $_[0]->NEXT::DESTROY() }

	package D;
	use base qw( B C );
	sub D::method   { print "$_[0]: D method\n";   $_[0]->NEXT::method() }
	sub D::AUTOLOAD { print "$_[0]: D AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
	sub D::DESTROY  { print "$_[0]: D dtor\n";     $_[0]->NEXT::DESTROY() }

	package main;

	my $obj = bless {}, "D";

	$obj->method();		# Calls D::method, A::method, C::method
	$obj->missing_method(); # Calls D::AUTOLOAD, B::AUTOLOAD, C::AUTOLOAD

	# Clean-up calls D::DESTROY, B::DESTROY, A::DESTROY, C::DESTROY


=head1 DESCRIPTION

NEXT.pm adds a pseudoclass named C<NEXT> to any program
that uses it. If a method C<m> calls C<$self->NEXT::m()>, the call to
C<m> is redispatched as if the calling method had not originally been found.

In other words, a call to C<$self->NEXT::m()> resumes the depth-first,
left-to-right search of C<$self>'s class hierarchy that resulted in the
original call to C<m>.

Note that this is not the same thing as C<$self->SUPER::m()>, which 
begins a new dispatch that is restricted to searching the ancestors
of the current class. C<$self->NEXT::m()> can backtrack
past the current class -- to look for a suitable method in other
ancestors of C<$self> -- whereas C<$self->SUPER::m()> cannot.

A typical use would be in the destructors of a class hierarchy,
as illustrated in the synopsis above. Each class in the hierarchy
has a DESTROY method that performs some class-specific action
and then redispatches the call up the hierarchy. As a result,
when an object of class D is destroyed, the destructors of I<all>
its parent classes are called (in depth-first, left-to-right order).

Another typical use of redispatch would be in C<AUTOLOAD>'ed methods.
If such a method determined that it was not able to handle a
particular call, it might choose to redispatch that call, in the
hope that some other C<AUTOLOAD> (above it, or to its left) might
do better.

Note that it is a fatal error for any method (including C<AUTOLOAD>)
to attempt to redispatch any method except itself. For example:

	sub D::oops { print "oops!\n"; $_[0]->NEXT::other_method() }


=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS AND IRRITATIONS

Because it's a module, not an integral part of the interpreter, NEXT.pm
has to guess where the surrounding call was found in the method
look-up sequence. In the presence of diamond inheritance patterns
it occasionally guesses wrong.

It's also too slow (despite caching).

Comment, suggestions, and patches welcome.

=head1 COPYRIGHT

 Copyright (c) 2000-2001, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
    and/or modified under the same terms as Perl itself.
