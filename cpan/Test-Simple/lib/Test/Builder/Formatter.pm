package Test::Builder::Formatter;
use strict;
use warnings;

use Carp qw/confess/;
use Scalar::Util qw/blessed/;

use Test::Builder::Util qw/new package_sub/;

sub handle {
    my $self = shift;
    my ($item) = @_;

    confess "Handler did not get a valid Test::Builder::Event object! ($item)"
        unless $item && blessed($item) && $item->isa('Test::Builder::Event');

    my $method = $item->type;

    # Not all formatters will handle all types.
    return 0 unless $self->can($method);

    $self->$method($item);

    return 1;
}

sub to_handler {
    my $self = shift;
    return sub { $self->handle(@_) };
}

sub listen {
    my $class = shift;
    my %params = @_;
    my $caller = caller;

    my $tb = $params{tb};
    $tb ||= package_sub($caller, 'TB_INSTANCE') ? $caller->TB_INSTANCE : undef;

    my $stream = delete $params{stream} || ($tb ? $tb->stream : undef) || Test::Builder::Stream->shared;

    my $id = delete $params{id};
    ($id) = ($class =~ m/^.*::([^:]+)$/g) unless $id;

    return $stream->listen($id => $class->new(%params));
}

1;

__END__

=head1 NAME

Test::Builder::Formatter - Base class for formatters

=head1 DESCRIPTION

Events go to L<Test::Builder::Stream> which then forwards them on to one or
more formatters. This module is a base class for formatters. You do not NEED to
use this module to write a formatter, but it can help.

=head1 TEST COMPONENT MAP

  [Test Script] > [Test Tool] > [Test::Builder] > [Test::Bulder::Stream] > [Event Formatter]
                                                                                   ^
                                                                             You are here

A test script uses a test tool such as L<Test::More>, which uses Test::Builder
to produce events. The events are sent to L<Test::Builder::Stream> which then
forwards them on to one or more formatters. The default formatter is
L<Test::Builder::Fromatter::TAP> which produces TAP output.

=head1 SYNOPSYS

    package My::Formatter;
    use base 'Test::Builder::Formatter';

    sub ok {
        my $self = shift;
        my ($event) = @_;

        ...
    }

    ...

    1;

=head2 TO USE IT

    use Test::More;
    use My::Formatter;

    # Creates a new instance of your listener. Any params you pass in will be
    # passed into the constructor. Exceptions: 'id', 'stream' and 'tb' which
    # are used directly by 'listen' if present.
    my $unlisten = My::Formatter->listen(...);

    # To stop listening:
    $unlisten->();

=head1 METHODS

=head2 PROVIDED

=over 4

=item $L = $class->new(%params)

Create a new instance. Arguments must be key => value pairs where the key is a
method name on the object.

=item $unlisten = $class->listen(%params)

=item $unlisten = $class->listen(id => 'foo', %params)

=item $unlisten = $class->listen(stream => $STREAM, %params)

=item $unlisten = $class->listen(tb => $BUILDER, %params)

Construct an instance using %params, and add it as a listener on the stream.
'id', 'stream', and 'tb' are special arguments that can be used to specify the
id of the listener, the stream to which the instance will listen, or the
L<Test::Builder> instance from which to find the stream.

=item $L->handle($event)

Forward the event on to the correct method.

=item $subref = $L->to_handler()

Returns an anonymous sub that accepts events as arguments and passes them into
handle() on this instance.

=back

=head2 FOR YOU TO WRITE

=over 4

=item $self->ok($event)

=item $self->note($event)

=item $self->diag($event)

=item $self->plan($event)

=item $self->finish($event)

=item $self->bail($event)

=item $self->child($event)

Any events given to the handle() method will be passed into the associated
sub. If the sub is not defined then events of that type will be ignored.

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
