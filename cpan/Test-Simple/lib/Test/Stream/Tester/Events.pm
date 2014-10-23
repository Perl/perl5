package Test::Stream::Tester::Events;
use strict;
use warnings;

use Scalar::Util qw/blessed/;

use Test::Stream::Tester::Events::Event;

sub new {
    my $class = shift;
    my $self = bless [map { Test::Stream::Tester::Events::Event->new($_->summary) } @_], $class;
    return $self;
}

sub next { shift @{$_[0]} };

sub seek {
    my $self = shift;
    my ($type) = @_;

    while (my $e = shift @$self) {
        return $e if $e->{type} eq $type;
    }

    return undef;
}

sub clone {
    my $self = shift;
    my $class = blessed($self);
    return bless [@$self], $class;
}

1;

=head1 NAME

Test::Stream::Tester::Events - Event list used by L<Test::Stream::Tester>.

=head1 DESCRIPTION

L<Test::Stream::Tester> converts lists of events into instances of this object
for use in various tools. You will probably never need to directly use this
class.

=head1 METHODS

=over 4

=item $events = $class->new(@EVENTS);

Create a new instance from a list of events.

=item $event = $events->next

Get the next event.

=item $event = $events->seek($type)

Get the next event of the specific type (not a package name).

=item $copy = $events->clone()

Clone the events list object in its current state.

=back

=encoding utf8

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
