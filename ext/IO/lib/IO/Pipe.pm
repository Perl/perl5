#

package IO::Pipe;

=head1 NAME

IO::pipe - supply object methods for pipes

=head1 SYNOPSIS

	use IO::Pipe;

	$pipe = new IO::Pipe;

	if($pid = fork()) { # Parent
	    $pipe->reader();

	    while(<$pipe> {
		....
	    }

	}
	elsif(defined $pid) { # Child
	    $pipe->writer();

	    print $pipe ....
	}

	or

	$pipe = new IO::Pipe;

	$pipe->reader(qw(ls -l));

	while(<$pipe>) {
	    ....
	}

=head1 DESCRIPTION

C<IO::Pipe> provides an interface to createing pipes between
processes.

=head1 CONSTRCUTOR

=over 4

=item new ( [READER, WRITER] )

Creates a C<IO::Pipe>, which is a reference to a
newly created symbol (see the C<Symbol> package). C<IO::Pipe::new>
optionally takes two arguments, which should be objects blessed into
C<IO::Handle>, or a subclass thereof. These two objects will be used
for the system call to C<pipe>. If no arguments are given then then
method C<handles> is called on the new C<IO::Pipe> object.

These two handles are held in the array part of the GLOB until either
C<reader> or C<writer> is called.

=back

=head1 METHODS

=over 4

=item reader ([ARGS])

The object is re-blessed into a sub-class of C<IO::Handle>, and becomes a
handle at the reading end of the pipe. If C<ARGS> are given then C<fork>
is called and C<ARGS> are passed to exec.

=item writer ([ARGS])

The object is re-blessed into a sub-class of C<IO::Handle>, and becomes a
handle at the writing end of the pipe. If C<ARGS> are given then C<fork>
is called and C<ARGS> are passed to exec.

=item handles ()

This method is called during construction by C<IO::Pipe::new>
on the newly created C<IO::Pipe> object. It returns an array of two objects
blessed into C<IO::Handle>, or a subclass thereof.

=back

=head1 SEE ALSO

L<IO::Handle>

=head1 AUTHOR

Graham Barr <bodg@tiuk.ti.com>

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

require 5.000;
use     strict;
use 	vars qw($VERSION);
use 	Carp;
use 	Symbol;
require IO::Handle;

$VERSION = "1.08";

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "IO::Pipe";
    @_ == 0 || @_ == 2 or croak "usage: new $class [READFH, WRITEFH]";

    my $me = bless gensym(), $class;

    my($readfh,$writefh) = @_ ? @_ : $me->handles;

    pipe($readfh, $writefh)
	or return undef;

    @{*$me} = ($readfh, $writefh);

    $me;
}

sub handles {
    @_ == 1 or croak 'usage: $pipe->handles()';
    (IO::Handle->new(), IO::Handle->new());
}

sub _doit {
    my $me = shift;
    my $rw = shift;

    my $pid = fork();

    if($pid) { # Parent
	return $pid;
    }
    elsif(defined $pid) { # Child
	my $fh = $rw ? $me->reader() : $me->writer();
	my $io = $rw ? \*STDIN : \*STDOUT;

	bless $io, "IO::Handle";
	$io->fdopen($fh, $rw ? "r" : "w");
	exec @_ or
	    croak "IO::Pipe: Cannot exec: $!";
    }
    else {
	croak "IO::Pipe: Cannot fork: $!";
    }

    # NOT Reached
}

sub reader {
    @_ >= 1 or croak 'usage: $pipe->reader()';
    my $me = shift;
    my $fh  = ${*$me}[0];
    my $pid = $me->_doit(0,@_)
	if(@_);

    close(${*$me}[1]);
    bless $me, ref($fh);
    *{*$me} = *{*$fh};			# Alias self to handle
    bless $fh, 'IO::Pipe::DeadEnd';	# Really wan't un-bless here
    ${*$me}{'io_pipe_pid'} = $pid
	if defined $pid;

    $me;
}

sub writer {
    @_ >= 1 or croak 'usage: $pipe->writer()';
    my $me = shift;
    my $fh  = ${*$me}[1];
    my $pid = $me->_doit(1,@_)
	if(@_);

    close(${*$me}[0]);
    bless $me, ref($fh);
    *{*$me} = *{*$fh};			# Alias self to handle
    bless $fh, 'IO::Pipe::DeadEnd';	# Really wan't un-bless here
    ${*$me}{'io_pipe_pid'} = $pid
	if defined $pid;

    $me;
}

1;

