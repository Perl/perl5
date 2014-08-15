package Test::Builder::Result::Ok;
use strict;
use warnings;

use base 'Test::Builder::Result';

use Carp qw/confess/;
use Scalar::Util qw/blessed reftype/;
use Test::Builder::Util qw/accessors/;

accessors qw/bool real_bool name todo skip/;

sub init_order {
    my $self = shift;
    my @attrs = @_;

    my @out;
    my $diag;
    for my $i (@attrs) {
        if ($i eq 'diag') {
            $diag++;
            next;
        }

        push @out => $i;
    }

    push @out => 'diag' if $diag;

    return @out;
}

sub pre_init {
    my $self = shift;
    my ($params) = @_;

    return if $params->{real_bool} || ($params->{skip} && $params->{todo});

    my $msg    = $params->{in_todo}   ? "Failed (TODO)" : "Failed";
    my $prefix = $ENV{HARNESS_ACTIVE} ? "\n"            : "";

    my ($pkg, $file, $line) = $params->{trace}->report->call;

    if (defined $params->{name}) {
        my $name = $params->{name};
        $msg = qq[$prefix  $msg test '$name'\n  at $file line $line.\n];
    }
    else {
        $msg = qq[$prefix  $msg test at $file line $line.\n];
    }

    $params->{diag} ||= [];
    unshift @{$params->{diag}} => $msg;
}

sub to_tap {
    my $self = shift;
    my ($num) = @_;

    my $out = "";
    $out .= "not " unless $self->real_bool;
    $out .= "ok";
    $out .= " $num" if defined $num;

    if (defined $self->name) {
        my $name = $self->name;
        $name =~ s|#|\\#|g;    # # in a name can confuse Test::Harness.
        $out .= " - " . $name;
    }

    if (defined $self->skip && defined $self->todo) {
        my $why = $self->skip;

        unless ($why eq $self->todo) {
            require Data::Dumper;
            confess "2 different reasons to skip/todo: " . Data::Dumper::Dumper($self);
        }

        $out .= " # TODO & SKIP $why";
    }
    elsif (defined $self->skip) {
        $out .= " # skip";
        $out .= " " . $self->skip if length $self->skip;
    }
    elsif($self->in_todo) {
        $out .= " # TODO " . $self->todo if $self->in_todo;
    }

    $out =~ s/\n/\n# /g;

    $out .= "\n";

    return $out;
}

sub clear_diag {
    my $self = shift;
    my @out = @{delete $self->{diag} || []};
    $_->linked(undef) for @out;
    return @out;
}

sub diag {
    my $self = shift;

    for my $i (@_) {
        next unless $i;
        my $type = reftype $i || "";

        my $array = $type eq 'ARRAY' ? $i : [$i];
        for my $d (@$array) {
            if (ref $d) {
                confess "Only Diag objects can be linked to results."
                    unless blessed($d) && $d->isa('Test::Builder::Result::Diag');

                confess "Diag argument '$d' is already linked to a result."
                    if $d->linked;
            }
            else {
                $d = Test::Builder::Result::Diag->new( message => $d );
            }

            for (qw/trace pid depth in_todo source/) {
                $d->$_($self->$_) unless $d->$_;
            }

            $d->linked($self);
            push @{$self->{diag}} => $d;
        }
    }

    return $self->{diag};
}

1;

__END__

=head1 NAME

Test::Builder::Result::Ok - Ok result type

=head1 DESCRIPTION

The ok result type.

=head1 METHODS

See L<Test::Builder::Result> which is the base class for this module.

=head2 CONSTRUCTORS

=over 4

=item $r = $class->new(...)

Create a new instance

=back

=head2 SIMPLE READ/WRITE ACCESSORS

=over 4

=item $r->bool

True if the test passed, or if we are in a todo/skip

=item $r->real_bool

True if the test passed, false otherwise, even in todo.

=item $r->name

Name of the test.

=item $r->todo

Reason for todo (may be empty, even in a todo, check in_todo().

=item $r->skip

Reason for skip

=item $r->trace

Get the test trace info, including where to report errors.

=item $r->pid

PID in which the result was created.

=item $r->depth

Builder depth of the result (0 for normal, 1 for subtest, 2 for nested, etc).

=item $r->in_todo

True if the result was generated inside a todo.

=item $r->source

Builder that created the result, usually $0, but the name of a subtest when
inside a subtest.

=item $r->constructed

Package, File, and Line in which the result was built.

=item $r->diag

Either undef, or an arrayref of L<Test::Builder::Result::Diag> objects. These
objects will be linked to this Ok result. Calling C<< $diag->linked >> on them
will return this Ok object. References here are strong references, references
to this object from the linked Diag objects are weakened to avoid cycles.

You can push diag objects into the arrayref by using them as arguments to this
method. Objects will be validated to ensure that they are Diag objects, and not
already linked to a result. As well C<linked> will be set on them.

=item $r->clear_diag

Remove all linked Diag objects, also removes the link within the Diags. Returns
a list of the objects.

=back

=head2 INFORMATION

=over 4

=item $r->to_tap

Returns the TAP string for the plan (not indented).

=item $r->type

Type of result. Usually this is the lowercased name from the end of the
package. L<Test::Builder::Result::Ok> = 'ok'.

=item $r->indent

Returns the indentation that should be used to display the result ('    ' x
depth).

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
