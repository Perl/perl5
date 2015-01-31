package Test::Stream::Tester::Events::Event;
use strict;
use warnings;

use Test::Stream::Carp qw/confess/;
use Scalar::Util qw/reftype blessed/;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my @orig = @_;

    while (@_) {
        my $field = shift;
        my $val   = shift;

        if (exists $self->{$field}) {
            use Data::Dumper;
            print Dumper(@orig);
            confess "'$field' specified more than once!";
        }

        if (my $type = reftype $val) {
            if ($type eq 'ARRAY') {
                $val = Test::Stream::Tester::Events->new(@$val)
                    unless grep { !blessed($_) || !$_->isa('Test::Stream::Event') } @$val;
            }
            elsif (blessed($val) && $val->isa('Test::Stream::Event')) {
                $val = $class->new($val->summary);
            }
        }

        $self->{$field} = $val;
    }

    return $self;
}

sub get {
    my $self = shift;
    my ($field) = @_;
    return $self->{$field};
}

sub debug {
    my $self = shift;

    my $type = $self->get('type');
    my $file = $self->get('file');
    my $line = $self->get('line');

    return "'$type' from $file line $line.";
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Tester::Events::Event - L<Test::Stream::Tester> representation of
an event.

=head1 DESCRIPTION

L<Test::Stream::Tester> often uses this clas to represent events in a way that
is easier to validate.

=head1 SYNOPSYS

    use Test::Stream::Tester::Events::Event;

    my $event = Test::Stream::Tester::Events::Event->new($e->summary);

    # Print the file and line number where the event was generated
    print "Debug: " . $event->debug . "\n";

    # Get an event field value
    my $val = $event->get($field);

=head1 METHODS

=over 4

=item $event->get($field)

Get the value of a specific event field. Fields are specific to event types.
The fields are usually the result of calling C<< $e->summary >> on the original
event.

=item $event->debug

Returns a string like this:

    'ok' from my_test.t line 42.

Which lists the type of event, the file that generated, and the line number on
which it was generated.

=back

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
