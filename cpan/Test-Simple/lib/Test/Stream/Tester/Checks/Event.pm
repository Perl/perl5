package Test::Stream::Tester::Checks::Event;
use strict;
use warnings;

use Test::Stream::Util qw/is_regex/;
use Test::Stream::Carp qw/confess croak/;

use Scalar::Util qw/blessed reftype/;

sub new {
    my $class = shift;
    my $fields = {@_};
    my $self = bless {fields => $fields}, $class;

    $self->{$_} = delete $fields->{$_}
        for qw/debug_line debug_file debug_package/;

    map { $self->validate_check($_) } values %$fields;

    my $type = $self->get('type') || confess "No type specified!";

    my $etypes = Test::Stream::Context->events;
    confess "'$type' is not a valid event type"
        unless $etypes->{$type};

    return $self;
}

sub debug_line    { shift->{debug_line}    }
sub debug_file    { shift->{debug_file}    }
sub debug_package { shift->{debug_package} }

sub debug {
    my $self = shift;

    my $type = $self->get('type');
    my $file = $self->debug_file;
    my $line = $self->debug_line;

    return "'$type' from $file line $line.";
}

sub keys { sort keys %{shift->{fields}} }

sub exists {
    my $self = shift;
    my ($field) = @_;
    return exists $self->{fields}->{$field};
}

sub get {
    my $self = shift;
    my ($field) = @_;
    return $self->{fields}->{$field};
}

sub validate_check {
    my $self = shift;
    my ($val) = @_;

    return unless defined $val;
    return unless ref $val;
    return if defined is_regex($val);

    if (blessed($val)) {
        return if $val->isa('Test::Stream::Tester::Checks');
        return if $val->isa('Test::Stream::Tester::Events');
        return if $val->isa('Test::Stream::Tester::Checks::Event');
        return if $val->isa('Test::Stream::Tester::Events::Event');
    }

    my $type = reftype($val);
    return if $type eq 'CODE';

    croak "'$val' is not a valid field check"
        unless reftype($val) eq 'ARRAY';

    croak "Arrayrefs given as field checks may only contain regexes"
        if grep { ! defined is_regex($_) } @$val;

    return;
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Tester::Checks::Event - Representation of an event validation
specification.

=head1 DESCRIPTION

Used internally by L<Test::Stream::Tester>. Please do not use directly. No
backwords compatability will be provided if the API for this module changes.

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
