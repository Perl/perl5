package Test::Builder::Trace::Frame;
use strict;
use warnings;

use Test::Builder::Util qw/accessors accessor is_provider is_tester/;

my %BUILDER_PACKAGES = (
    __PACKAGE__, 1,
    'Test::Builder'                => 1,
    'Test::Builder::Event'        => 1,
    'Test::Builder::Event::Bail'  => 1,
    'Test::Builder::Event::Child' => 1,
    'Test::Builder::Event::Diag'  => 1,
    'Test::Builder::Event::Note'  => 1,
    'Test::Builder::Event::Ok'    => 1,
    'Test::Builder::Event::Plan'  => 1,
    'Test::Builder::Stream'        => 1,
    'Test::Builder::Trace'         => 1,
    'Test::Builder::Util'          => 1,
);

accessors qw{
    depth package file line subname todo
    level report
};

sub new {
    my $class = shift;
    my ($depth, $pkg, $file, $line, $sub, $todo) = @_;

    return bless {
        depth   => $depth || 0,
        package => $pkg   || undef,
        file    => $file  || undef,
        line    => $line  || 0,
        subname => $sub   || undef,
        todo    => $todo  || undef,
    }, $class;
}

sub call {
    my $self = shift;
    return (
        $self->package,
        $self->file,
        $self->line,
        $self->subname,
    );
}

accessor transition => sub {
    my $self = shift;

    return 0 if $self->builder;

    my $subname = $self->subname;
    return 0 unless $subname;
    return 0 unless $subname =~ m/^(.*)::([^:]+)$/;
    my ($pkg, $sub) = ($1, $2);

    return $BUILDER_PACKAGES{$pkg} || 0;
};

accessor nest => sub {
    my $self = shift;
    return 0 unless $self->subname eq 'Test::Builder::Trace::nest';
    return 1;
};

accessor builder => sub {
    my $self = shift;
    return 0 unless $BUILDER_PACKAGES{$self->package};
    return 1;
};

accessor anointed => sub {
    my $self = shift;
    return 0 unless is_tester($self->package);
    return 0 if $self->subname eq 'Test::Builder::subtest';
    return 1;
};

accessor provider_tool => sub {
    my $self = shift;

    my $subname = $self->subname;
    return undef if $subname eq '(eval)';

    my $attrs;
    if ($subname =~ m/^Test\::Builder\::Provider\::__ANON(\d+)__/) {
        no strict 'refs';
        return \%{$subname};
    }
    else {
        my ($pkg, $sub) = ($subname =~ m/^(.+)::([_\w][_\w0-9]*)/);
        if (is_provider($pkg) && $sub && $sub ne '__ANON__') {
            $attrs = $pkg->TB_PROVIDER_META->{attrs}->{$sub};
            return $attrs if $attrs->{named};
        }
    }

    return undef;
};

1;

=pod

=head1 NAME

Test::Builder::Trace::Frame - Module to represent a stack frame

=head1 DESCRIPTION

When a test fails it will report the filename and line where the failure
occured . In order to do this it needs to look at the stack and figure out
where your tests stop, and the tools you are using begin . This object
represents a single stack frame .

=head1 CLASS METHODS

=over 4

=item $frame = $class->new($depth, $package, $file, $line, $sub)

Create a new instance.

    my $frame = $class->new(4, caller(4));

=back

=head1 UTILITY METHODS

=over 4

=item @call = $frame->call

=item ($pkg, $file, $line, $subname) = $frame->call

Returns a list similar to calling C<caller()>.

=back

=head1 ACCESSORS

=over 4

=item $depth = $frame->depth

Depth of the frame in the stack

=item $package = $frame->package

Package of the frame

=item $file = $frame->file

File of the frame

=item $line = $frame->line

Line of the frame

=item $subname = $frame->subname

Name of sub being called

=item $attrs = $frame->provider_tool

If the frame is a call to a provider tool this will contain the attribute
hashref for that tool. This returns undef when the call was not to a provider
tool.

=back

=head1 CALCULATED BOOLEAN ATTRIBUTES

The state of these booleans will be determined the first time they are called.
They will be cached for future calls.

=over 4

=item $todo = $frame->todo

Returns the TODO message if $TODO is set in the package the frame is from.

=item $bool = $frame->nest

True if the frame is a call to L<Test::Builder::Trace::nest()>.

=item $bool = $frame->builder

True if the frame is inside Test::Builder code.

=item $bool = $frame->transition

True if the frame is a transition between Test::Builder and Non-Test::Builder
code.

=item $bool = $frame->anointed

True if the frame is a call from an annointed test package.

=back

=head1 BOOLEAN ATTRIBUTES

B<Note> None of these are set automatically by the constructor or any other
calls. These get set by L<Test::Builder::Trace> when it scans the stack. It
will never be useful to check these on a frame object you created yourself.

=over 4

=item $bool = $frame->level

True if the frame is associated with C<$Test::Builder::Level>.

=item $bool = $frame->report

True if the frame has been chosen as the reporting frame.

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2014 by Chad Granum E<lt>exodist7@gmail.comE<gt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

