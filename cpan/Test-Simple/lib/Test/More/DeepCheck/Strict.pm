package Test::More::DeepCheck::Strict;
use strict;
use warnings;

use Scalar::Util qw/reftype/;
use Test::More::Tools;
use Test::Stream::Carp qw/cluck confess/;
use Test::Stream::Util qw/try unoverload_str is_regex/;

use Test::Stream::ArrayBase(
    accessors => [qw/stack_start/],
    base => 'Test::More::DeepCheck',
);

sub preface { "Structures begin differing at:\n" }

sub check {
    my $class = shift;
    my ($got, $expect) = @_;

    unoverload_str(\$got, \$expect);
    my $self = $class->new();

    # neither is a reference
    return tmt->is_eq($got, $expect)
        if !ref $got and !ref $expect;

    # one's a reference, one isn't
    if (!ref $got xor !ref $expect) {
        push @$self => {vals => [$got, $expect], line => __LINE__};
        return (0, $self->format_stack);
    }

    push @$self => {vals => [$got, $expect], line => __LINE__};
    my $ok = $self->_deep_check($got, $expect);
    return ($ok, $ok ? () : $self->format_stack);
}

sub check_array {
    my $class = shift;
    my ($got, $expect) = @_;
    my $self = $class->new();
    push @$self => {vals => [$got, $expect], line => __LINE__};
    my $ok = $self->_deep_check($got, $expect);
    return ($ok, $ok ? () : $self->format_stack);
}

sub check_hash {
    my $class = shift;
    my ($got, $expect) = @_;
    my $self = $class->new();
    push @$self => {vals => [$got, $expect], line => __LINE__};
    my $ok = $self->_deep_check($got, $expect);
    return ($ok, $ok ? () : $self->format_stack);
}

sub check_set {
    my $class = shift;
    my ($got, $expect) = @_;

    return 0 unless @$got == @$expect;

    no warnings 'uninitialized';

    # It really doesn't matter how we sort them, as long as both arrays are
    # sorted with the same algorithm.
    #
    # Ensure that references are not accidentally treated the same as a
    # string containing the reference.
    #
    # Have to inline the sort routine due to a threading/sort bug.
    # See [rt.cpan.org 6782]
    #
    # I don't know how references would be sorted so we just don't sort
    # them.  This means eq_set doesn't really work with refs.
    return $class->check_array(
        [ grep( ref, @$got ),    sort( grep( !ref, @$got ) )    ],
        [ grep( ref, @$expect ), sort( grep( !ref, @$expect ) ) ],
    );
}

sub _deep_check {
    my $self = shift;
    confess "XXX" unless ref $self;
    my($e1, $e2) = @_;

    unoverload_str( \$e1, \$e2 );

    # Either they're both references or both not.
    my $same_ref = !(!ref $e1 xor !ref $e2);
    my $not_ref  =  (!ref $e1 and !ref $e2);

    return 0 if  defined $e1 xor  defined $e2;
    return 1 if !defined $e1 and !defined $e2; # Shortcut if they're both undefined.
    return 0 if  $self->is_dne($e1) xor $self->is_dne($e2);
    return 1 if  $same_ref   and ($e1 eq $e2);

    if ($not_ref) {
        push @$self => {type => '', vals => [$e1, $e2], line => __LINE__};
        return 0;
    }

    # This avoids picking up the same referenced used twice (such as
    # [\$a, \$a]) to be considered circular.
    my $seen = {%{$self->[SEEN]->[-1]}};
    push @{$self->[SEEN]} => $seen;
    my $ok = $self->_inner_check($seen, $e1, $e2);
    pop @{$self->[SEEN]};
    return $ok;
}

sub _inner_check {
    my $self = shift;
    my ($seen, $e1, $e2) = @_;

    return $seen->{$e1} if $seen->{$e1} && $seen->{$e1} eq $e2;
    $seen->{$e1} = "$e2";

    my $type1 = reftype($e1) || '';
    my $type2 = reftype($e2) || '';
    my $diff  = $type1 ne $type2;

    if ($diff) {
        push @$self => {type => 'DIFFERENT', vals => [$e1, $e2], line => __LINE__};
        return 0;
    }

    return $self->_check_array($e1, $e2) if $type1 eq 'ARRAY';
    return $self->_check_hash($e1, $e2)  if $type1 eq 'HASH';

    if ($type1 eq 'REF' || $type1 eq 'SCALAR' && !(defined(is_regex($e1)) && defined(is_regex($e2)))) {
        push @$self => {type => 'REF', vals => [$e1, $e2], line => __LINE__};
        my $ok = $self->_deep_check($$e1, $$e2);
        pop @$self if $ok;
        return $ok;
    }

    push @$self => {type => $type1, vals => [$e1, $e2], line => __LINE__};
    return 0;
}

sub _check_array {
    my $self = shift;
    my ($a1, $a2) = @_;

    if (grep reftype($_) ne 'ARRAY', $a1, $a2) {
        cluck "_check_array passed a non-array ref";
        return 0;
    }

    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for (0 .. $max) {
        my $e1 = $_ > $#$a1 ? $self->dne : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $self->dne : $a2->[$_];

        next if $self->_check_nonrefs($e1, $e2);

        push @$self => {type => 'ARRAY', idx => $_, vals => [$e1, $e2], line => __LINE__};
        $ok = $self->_deep_check($e1, $e2);
        pop @$self if $ok;

        last unless $ok;
    }

    return $ok;
}

sub _check_nonrefs {
    my $self = shift;
    my($e1, $e2) = @_;

    return if ref $e1 or ref $e2;

    if (defined $e1) {
        return 1 if defined $e2 and $e1 eq $e2;
    }
    else {
        return 1 if !defined $e2;
    }

    return 0;
}

sub _check_hash {
    my $self = shift;
    my ($a1, $a2) = @_;

    if (grep {(reftype($_) || '') ne 'HASH' } $a1, $a2) {
        cluck "_check_hash passed a non-hash ref";
        return 0;
    }

    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    for my $k (sort keys %$bigger) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $self->dne;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $self->dne;

        next if $self->_check_nonrefs($e1, $e2);

        push @$self => {type => 'HASH', idx => $k, vals => [$e1, $e2], line => __LINE__};
        $ok = $self->_deep_check($e1, $e2);
        pop @$self if $ok;

        last unless $ok;
    }

    return $ok;
}

1;

__END__

=head1 NAME

Test::More::DeepCheck::Strict - Where is_deeply() is implemented.

=head1 DESCRIPTION

This is the package where the code for C<is_deeply()> from L<Test::More> lives.
This code was refactored into this form, but should remain 100% compatible with
the old implementation. If you find an incompatability please report it.

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
