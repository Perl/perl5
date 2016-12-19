package Test2::Event::Info;
use strict;
use warnings;

use Scalar::Util qw/blessed/;

our $VERSION = '1.302073';

BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw/diagnostics renderer/;

sub init {
    my $self = shift;

    my $r = $self->{+RENDERER} or $self->trace->throw("'renderer' is a required attribute");

    return if ref($r) eq 'CODE';
    return if blessed($r) && $r->can('render');

    $self->trace->throw("renderer '$r' is not a valid renderer, must be a coderef or an object implementing the 'render()' method");
}

sub render {
    my $self = shift;
    my ($fmt) = @_;

    $fmt ||= 'text';

    my $r = $self->{+RENDERER};

    return $r->($fmt) if ref($r) eq 'CODE';
    return $r->render($fmt);
}

sub summary { $_[0]->render($_[1] || 'text') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Event::Info - Info event base class

=head1 DESCRIPTION

Successor for note and diag events. This event base class supports multiple
formats. This event makes it possible to send additional information such as
color and highlighting to the harness.

=head1 SYNOPSIS

    use Test2::API::Context qw/context/;

    $ctx->info($obj, diagnostics => $bool);

=head1 FORMATS

Format will be passed in to C<render()> and C<summary()> as a string. Any
string is considered valid, if your event does not recognize the format it
should fallback to 'text'.

=over 4

=item 'text'

Plain and ordinary text.

=item 'ansi'

Text that may include ansi sequences such as colors.

=item 'html'

HTML formatted text.

=back

=head1 ACCESSORS

=over 4

=item $bool = $info->diagnostics()

=item $info->set_diagnostics($bool)

True if this info is essential for diagnostics. The implication is that
diagnostics will got to STDERR while everything else goes to STDOUT, but that
is formatter/harness specific.

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
