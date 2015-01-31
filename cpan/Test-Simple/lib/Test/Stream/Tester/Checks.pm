package Test::Stream::Tester::Checks;
use strict;
use warnings;

use Test::Stream::Carp qw/croak confess/;
use Test::Stream::Util qw/is_regex/;

use Scalar::Util qw/blessed reftype/;

my %DIRECTIVES = (
    map { $_ => __PACKAGE__->can($_) }
        qw(filter_providers filter_types skip seek end)
);

sub new {
    my $class = shift;
    my ($file, $line) = @_;
    my $self = bless {
        seek  => 0,
        items => [],
        file  => $file,
        line  => $line,
    }, $class;
    return $self;
}

sub debug {
    my $self = shift;
    return "Checks from $self->{file} around line $self->{line}.";
}

sub populated { scalar @{shift->{items}} }

sub add_directive {
    my $self = shift;
    my ($dir, @args) = @_;

    confess "No directive provided!"
        unless $dir;

    if (ref($dir)) {
        confess "add_directive takes a coderef, or name, and optional args. (got $dir)"
            unless reftype($dir) eq 'CODE';
    }
    else {
        confess "$dir is not a valid directive."
            unless $DIRECTIVES{$dir};
        $dir = $DIRECTIVES{$dir};
    }

    push @{$self->{items}} => [$dir, @args];
}

sub add_event {
    my $self = shift;
    my ($type, $spec) = @_;

    confess "add_event takes a type name and a hashref"
        unless $type && $spec && ref $spec && reftype($spec) eq 'HASH';

    my $e = Test::Stream::Tester::Checks::Event->new(%$spec, type => $type);
    push @{$self->{items}} => $e;
}

sub include {
    my $self = shift;
    my ($other) = @_;

    confess "Invalid argument to include()"
        unless $other && blessed($other) && $other->isa(__PACKAGE__);

    push @{$self->{items}} => @{$other->{items}};
}

sub run {
    my $self = shift;
    my ($events) = @_;
    $events = $events->clone;

    for (my $i = 0; $i < @{$self->{items}}; $i++) {
        my $item = $self->{items}->[$i];

        # Directive
        if (reftype $item eq 'ARRAY') {
            my ($code, @args) = @$item;
            my @out = $self->$code($events, @args);
            next unless @out;
            return @out;
        }

        # Event!
        my $meth = $self->{seek} ? 'seek' : 'next';
        my $event = $events->$meth($item->get('type'));

        my ($ret, @debug) = $self->check_event($item, $event);
        return ($ret, @debug) unless $ret;
    }

    return (1);
}

sub vtype {
    my ($v) = @_;

    if (blessed($v)) {
        return 'checks' if $v->isa('Test::Stream::Tester::Checks');
        return 'events' if $v->isa('Test::Stream::Tester::Events');
        return 'check'  if $v->isa('Test::Stream::Tester::Checks::Event');
        return 'event'  if $v->isa('Test::Stream::Tester::Events::Event');
    }

    return 'regexp' if defined is_regex($v);
    return 'noref' unless ref $v;
    return 'array'  if reftype($v) eq 'ARRAY';
    return 'code'   if reftype($v) eq 'CODE';

    confess "Invalid field check: '$v'";
}

sub check_event {
    my $self = shift;
    my ($want, $got) = @_;

    my @debug = ("  Check: " . $want->debug);
    my $wtype = $want->get('type');

    return (0, @debug, "  Expected event of type '$wtype', but did not find one.")
        unless defined($got);

    unshift @debug => "  Event: " . $got->debug;
    my $gtype = $got->get('type');

    return (0, @debug, "  Expected event of type '$wtype', but got '$gtype'.")
        unless $wtype eq $gtype;

    for my $key ($want->keys) {
        my $wval = $want->get($key);
        my $gval = $got->get($key);

        my ($ret, @err) = $self->check_key($key, $wval, $gval);
        return ($ret, @debug, @err) unless $ret;
    }

    return (1);
}

sub check_key {
    my $self = shift;
    my ($key, $wval, $gval) = @_;

    if ((defined $wval) xor(defined $gval)) {
        $wval = defined $wval ? "'$wval'" : 'undef';
        $gval = defined $gval ? "'$gval'" : 'undef';
        return (0, "  \$got->{$key} = $gval", "  \$exp->{$key} = $wval",);
    }

    my $wtype = vtype($wval);

    my $meth = "_check_field_$wtype";
    return $self->$meth($key, $wval, $gval);
}

sub _check_field_checks {
    my $self = shift;
    my ($key, $wval, $gval) = @_;

    my $debug = $wval->debug;

    return (0, "  \$got->{$key} = '$gval'", "  \$exp->{$key} = <$debug>")
        unless vtype($gval) eq 'events';

    my ($ret, @diag) = $wval->run($gval);
    return $ret if $ret;
    return ($ret, map { s/^/    /mg; $_ } @diag);
}

sub _check_field_check {
    my $self = shift;
    my ($key, $wval, $gval) = @_;

    my $debug = $wval->debug;

    return (0, "Event: INVALID EVENT ($gval)", "  Check: $debug")
        unless vtype($gval) eq 'event';

    my ($ret, @diag) = check_event($wval, $gval);
    return $ret if $ret;

    return ($ret, map { s/^/    /mg; $_ } @diag);
}

sub _check_field_noref {
    my $self = shift;
    my ($key, $wval, $gval) = @_;

    return (1) if !defined($wval) && !defined($gval);
    return (1) if defined($wval) && defined($gval) && "$wval" eq "$gval";
    $wval = "'$wval'" if defined $wval;
    $wval ||= 'undef';
    $gval = "'$gval'" if defined $gval;
    $gval ||= 'undef';
    return (0, "  \$got->{$key} = $gval", "  \$exp->{$key} = $wval");
}

sub _check_field_regexp {
    my $self = shift;
    my ($key, $wval, $gval) = @_;

    return (1) if $gval =~ /$wval/;
    return (0, "  \$got->{$key} = '$gval'", "  Does not match $wval");
}

sub _check_field_array {
    my $self = shift;
    my ($key, $wval, $gval) = @_;
    for my $p (@$wval) {
        my ($ret, @diag) = $self->_check_field_regexp($key, $p, $gval);
        return ($ret, @diag) unless $ret;
    }

    return (1);
}

sub _check_field_code {
    my $self = shift;
    my ($key, $wval, $gval) = @_;
    $wval->($key, $gval);
}

sub seek {
    my $self = shift;
    my ($events, $flag) = @_;

    $self->{seek} = $flag ? 1 : 0;

    return (); # Cannot fail
}

sub skip {
    my $self = shift;
    my ($events, $num) = @_;
    $events->next while $num--;
    return ();
}

sub end {
    my $self = shift;
    my ($events) = @_;
    my $event = $events->next;
    return () unless $event;
    return (0, "  Expected end of events, got " . $event->debug);
}

sub filter_providers {
    my $self = shift;
    my ($events, $arg) = @_;

    my ($neg, $val) = $arg =~ m/^(!?)(.*)$/;
    if ($neg) {
        @$events = grep { $_->get('tool_package') ne $val } @$events;
    }
    else {
        @$events = grep { $_->get('tool_package') eq $val } @$events;
    }

    return ();
}

sub filter_types {
    my $self = shift;
    my ($events, $arg) = @_;

    my ($neg, $val) = $arg =~ m/^(!?)(.*)$/;
    if ($neg) {
        @$events = grep { $_->get('type') ne $val } @$events;
    }
    else {
        @$events = grep { $_->get('type') eq $val } @$events;
    }

    return ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Tester::Checks - Representation of a L<Test::Stream::Tester>
event check.

=head1 DESCRIPTION

L<Test::Stream::Tester> produces this object whenever you use C<check { ... }>.
In general you will not interact with this object directly beyond pasing it
into C<events_are>.

B<Note:> The API for this object is not published and is subject to change. No backwords
compatability can be guarenteed if you use this object directly. Please only
use this object in the published way specified in L<Test::Stream::Tester>.

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
