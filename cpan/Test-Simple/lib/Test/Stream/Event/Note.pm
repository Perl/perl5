package Test::Stream::Event::Note;
use strict;
use warnings;

use Test::Stream::Event(
    accessors  => [qw/message/],
    ctx_method => '_note',
);

use Test::Stream::Carp qw/confess/;

sub init {
    $_[0]->SUPER::init();
    $_[0]->[MESSAGE] = 'undef' unless defined $_[0]->[MESSAGE];
}

sub to_tap {
    my $self = shift;

    chomp(my $msg = $self->[MESSAGE]);
    $msg = "# $msg" unless $msg =~ m/^\n/;
    $msg =~ s/\n/\n# /g;

    return [OUT_STD, "$msg\n"];
}

sub extra_details {
    my $self = shift;
    return ( message => $self->message || '' );
}

1;

__END__

=head1 NAME

Test::Stream::Event::Note - Note event type

=encoding utf8

=head1 DESCRIPTION

Notes, typically rendered to STDOUT.

=head1 SYNOPSYS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Note;

    my $ctx = context();
    my $event = $ctx->Note($message);

=head1 ACCESSORS

=over 4

=item $note->message

The message for the note.

=back

=head1 SUMMARY FIELDS

=over 4

=item message

The message from the note.

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
