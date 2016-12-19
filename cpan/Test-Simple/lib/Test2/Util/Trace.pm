package Test2::Util::Trace;
use strict;
use warnings;

our $VERSION = '1.302073';


use Test2::Util qw/get_tid pkg_to_file/;

use Carp qw/confess/;

use Test2::Util::HashBase qw{frame detail pid tid};

sub init {
    confess "The 'frame' attribute is required"
        unless $_[0]->{+FRAME};

    $_[0]->{+PID} = $$        unless defined $_[0]->{+PID};
    $_[0]->{+TID} = get_tid() unless defined $_[0]->{+TID};
}

sub snapshot { bless {%{$_[0]}}, __PACKAGE__ };

sub debug {
    my $self = shift;
    return $self->{+DETAIL} if $self->{+DETAIL};
    my ($pkg, $file, $line) = $self->call;
    return "at $file line $line";
}

sub alert {
    my $self = shift;
    my ($msg) = @_;
    warn $msg . ' ' . $self->debug . ".\n";
}

sub throw {
    my $self = shift;
    my ($msg) = @_;
    die $msg . ' ' . $self->debug . ".\n";
}

sub call { @{$_[0]->{+FRAME}} }

sub package { $_[0]->{+FRAME}->[0] }
sub file    { $_[0]->{+FRAME}->[1] }
sub line    { $_[0]->{+FRAME}->[2] }
sub subname { $_[0]->{+FRAME}->[3] }

sub from_json {
    my $class = shift;
	my %p     = @_;

    my $trace_pkg = delete $p{__PACKAGE__};
	require(pkg_to_file($trace_pkg));

    return $trace_pkg->new(%p);
}

sub TO_JSON {
    my $self = shift;
    return {%$self, __PACKAGE__ => ref $self};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Util::Trace - Debug information for events

=head1 DESCRIPTION

The L<Test2::API::Context> object, as well as all L<Test2::Event> types need to
have access to information about where they were created.  This object
represents that information.

=head1 SYNOPSIS

    use Test2::Util::Trace;

    my $trace = Test2::Util::Trace->new(
        frame => [$package, $file, $line, $subname],
    );

=head1 METHODS

=over 4

=item $trace->set_detail($msg)

=item $msg = $trace->detail

Used to get/set a custom trace message that will be used INSTEAD of
C<< at <FILE> line <LINE> >> when calling C<< $trace->debug >>.

=item $str = $trace->debug

Typically returns the string C<< at <FILE> line <LINE> >>. If C<detail> is set
then its value will be returned instead.

=item $trace->alert($MESSAGE)

This issues a warning at the frame (filename and line number where
errors should be reported).

=item $trace->throw($MESSAGE)

This throws an exception at the frame (filename and line number where
errors should be reported).

=item $frame = $trace->frame()

Get the call frame arrayref.

=item ($package, $file, $line, $subname) = $trace->call()

Get the caller details for the debug-info. This is where errors should be
reported.

=item $pkg = $trace->package

Get the debug-info package.

=item $file = $trace->file

Get the debug-info filename.

=item $line = $trace->line

Get the debug-info line number.

=item $subname = $trace->subname

Get the debug-info subroutine name.

=item $hashref = $t->TO_JSON

This returns a hashref suitable for passing to the C<<
Test2::Util::Trace->from_json >> constructor. It is intended for use with the
L<JSON> family of modules, which will look for a C<TO_JSON> method when
C<convert_blessed> is true.

=item $t = Test2::Util::Trace->from_json(%$hashref)

Given the hash of data returned by C<< $t->TO_JSON >>, this method returns a
new trace object of the appropriate subclass.

=back

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
