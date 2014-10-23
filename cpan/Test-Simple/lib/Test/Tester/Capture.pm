package Test::Tester::Capture;
use strict;
use warnings;

use base 'Test::Builder';
use Test::Stream qw/-internal STATE_LEGACY/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::create(@_);
    $self->{stream}->set_use_tap(0);
    $self->{stream}->set_use_legacy(1);
    return $self;
}

sub details {
    my $self = shift;

    my $prem;
    my @out;
    for my $e (@{$self->{stream}->state->[-1]->[STATE_LEGACY]}) {
        if ($e->isa('Test::Stream::Event::Ok')) {
            push @out => $e->to_legacy;
            $out[-1]->{diag} ||= "";
            $out[-1]->{depth} = $e->level;
            for my $d (@{$e->diag || []}) {
                next if $d->message =~ m{Failed test .*\n\s*at .* line \d+\.};
                chomp(my $msg = $d->message);
                $msg .= "\n";
                $out[-1]->{diag} .= $msg;
            }
        }
        elsif ($e->isa('Test::Stream::Event::Diag')) {
            chomp(my $msg = $e->message);
            $msg .= "\n";
            if (!@out) {
                $prem .= $msg;
                next;
            }
            next if $msg =~ m{Failed test .*\n\s*at .* line \d+\.};
            $out[-1]->{diag} .= $msg;
        }
    }

    return ($prem, @out) if $prem;
    return @out;
}

1;

__END__

=head1 NAME

Test::Tester::Capture - Capture module for TesT::Tester

=head1 DESCRIPTION

Legacy support for Test::Tester.

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
